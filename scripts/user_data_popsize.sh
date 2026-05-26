#!/bin/bash
set -euo pipefail
exec > /tmp/popsize_$(date +%Y%m%d_%H%M%S).log 2>&1

BUCKET="sima-egarmo-2026"
REGION="eu-west-1"
WORKDIR="/tmp/popsize"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p ${WORKDIR}/{bams,ref,results/het,results/roh}
cd ${WORKDIR}

log() { echo "[$(date '+%H:%M:%S')] $*"; aws s3 cp /tmp/popsize_*.log s3://${BUCKET}/popsize/logs/ --region ${REGION} 2>/dev/null || true; }

# ── 1. Dependencias ──────────────────────────────────
log "Instalando dependencias..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq samtools bcftools wget python3-pip unzip

pip3 install -q rohan

# ANGSD
wget -q https://github.com/ANGSD/angsd/releases/download/0.941/angsd0.941.tar.gz
tar xzf angsd0.941.tar.gz
cd angsd && make -j8 > /dev/null 2>&1 && cd ..
export PATH="${WORKDIR}/angsd:${WORKDIR}/angsd/misc:$PATH"
log "✓ Dependencias listas"

# ── 2. Referencia hg38 ───────────────────────────────
log "Descargando hg38 desde UCSC..."
wget -q https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz \
     -O ref/hg38.fa.gz
gunzip ref/hg38.fa.gz
samtools faidx ref/hg38.fa
log "✓ hg38 listo"

# Subir a S3 para próximas veces
aws s3 cp ref/hg38.fa.gz s3://${BUCKET}/ref/hg38.fa.gz --region ${REGION} &

# ── 3. Descargar BAMs rescaled ───────────────────────
log "Descargando BAMs..."
SPECIMENS="femurXIII femur_fragment incisor molar_L35 scapula"
for SP in $SPECIMENS; do
    aws s3 cp s3://${BUCKET}/sima_hg38/results/bam_rescaled/${SP}.rescaled.bam \
        bams/${SP}.bam --region $REGION
    aws s3 cp s3://${BUCKET}/sima_hg38/results/bam_rescaled/${SP}.rescaled.bam.bai \
        bams/${SP}.bam.bai --region $REGION
    log "  ✓ ${SP}"
done
ls bams/*.bam > bams.list

# ── 4. ANGSD — heterozigosidad por individuo ─────────
log "ANGSD: heterozigosidad individual (solo transversiones)..."
CHROMS="chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22"

for SP in $SPECIMENS; do
    log "  ANGSD ${SP}..."
    angsd \
        -i bams/${SP}.bam \
        -ref ref/hg38.fa \
        -anc ref/hg38.fa \
        -doSaf 1 \
        -GL 1 \
        -P 8 \
        -minMapQ 30 \
        -minQ 20 \
        -noTrans 1 \
        -checkBamHeaders 0 \
        -out results/het/${SP} 2>/dev/null || log "  WARN: ${SP} ANGSD falló"

    if [ -f results/het/${SP}.saf.idx ]; then
        realSFS results/het/${SP}.saf.idx > results/het/${SP}.sfs
        log "  ✓ ${SP} SFS OK"
    fi
done

# ── 5. ANGSD — pool-seq ──────────────────────────────
log "ANGSD: pool-seq (diversidad poblacional)..."
angsd \
    -bam bams.list \
    -ref ref/hg38.fa \
    -doMaf 4 \
    -doMajorMinor 1 \
    -GL 1 \
    -P 8 \
    -minMapQ 30 \
    -minQ 20 \
    -noTrans 1 \
    -minInd 3 \
    -setMinDepth 5 \
    -checkBamHeaders 0 \
    -out results/het/sima_pool 2>/dev/null || log "WARN: pool-seq falló"
log "✓ Pool-seq listo"

# ── 6. ROHan ─────────────────────────────────────────
log "ROHan — ROH por individuo..."
for SP in $SPECIMENS; do
    log "  ROHan ${SP}..."
    rohan \
        --rohmu 3e-5 \
        --size 3000000 \
        -t 4 \
        ref/hg38.fa \
        bams/${SP}.bam \
        > results/roh/${SP}_rohan.txt 2>&1 || log "  WARN: ROHan ${SP} falló"
    log "  ✓ ROHan ${SP}"
done

# ── 7. Calcular H y Ne ───────────────────────────────
log "Calculando H y Ne..."
python3 << 'PYEOF'
import os, math

specimens = ["femurXIII", "femur_fragment", "incisor", "molar_L35", "scapula"]
mu = 1.25e-8
results = []

for sp in specimens:
    sfs_file = f"results/het/{sp}.sfs"
    try:
        with open(sfs_file) as f:
            vals = list(map(float, f.read().split()))
        total = sum(vals)
        H = vals[1] / total if total > 0 else 0
        Ne = H / (4 * mu * (1 - H)) if H > 0 else 0
        results.append((sp, H, Ne, total))
    except Exception as e:
        results.append((sp, -1, -1, 0))

print("\n=== RESULTADOS SIMA DE LOS HUESOS ===")
print(f"{'Espécimen':<20} {'H observada':>12} {'Ne estimado':>12} {'Sitios':>12}")
print("-" * 60)
for sp, H, Ne, sites in results:
    if H >= 0:
        print(f"{sp:<20} {H:>12.6f} {Ne:>12.0f} {sites:>12.0f}")
    else:
        print(f"{sp:<20} {'ERROR':>12} {'ERROR':>12} {'0':>12}")

print("\n=== REFERENCIA PUBLICADA ===")
ref_data = [
    ("Vindija (Prüfer 2014)",   0.000700, 3000),
    ("D17 Denisova",            0.000500, 1500),
    ("Ust-Ishim (Fu 2014)",     0.001000, 7000),
    ("Humano AFR (gnomAD)",     0.001300, 10000),
]
print(f"{'Población':<25} {'H':>12} {'Ne':>12}")
print("-" * 52)
for name, H, Ne in ref_data:
    print(f"{name:<25} {H:>12.6f} {Ne:>12.0f}")

# Guardar tabla
with open("results/Ne_summary.tsv", "w") as f:
    f.write("specimen\tH_observed\tNe_estimated\tn_sites\n")
    for sp, H, Ne, sites in results:
        f.write(f"{sp}\t{H:.6f}\t{Ne:.0f}\t{sites:.0f}\n")
    f.write("\n# Referencias publicadas\n")
    for name, H, Ne in ref_data:
        f.write(f"{name}\t{H:.6f}\t{Ne:.0f}\tNA\n")
PYEOF

# ── 8. Subir resultados ──────────────────────────────
log "Subiendo resultados..."
aws s3 sync results/ s3://${BUCKET}/popsize/results_${TIMESTAMP}/ \
    --region $REGION
aws s3 cp /tmp/popsize_*.log \
    s3://${BUCKET}/popsize/logs/ --region $REGION

log "✅ ANÁLISIS COMPLETO — s3://${BUCKET}/popsize/results_${TIMESTAMP}/"
cat results/Ne_summary.tsv

sleep 90
sudo shutdown -h now
