#!/usr/bin/env bash
# =============================================================================
# downsample_vindija.sh — Test de viabilidad de PopSize
#
# PREGUNTA: ¿Puede el pipeline de PopSize (ANGSD -doSaf 1 -GL 1 -noTrans 1 +
# realSFS, H = SFS[1]/sum) estimar la heterozigosidad de un genoma con la
# cobertura que tienen los especímenes de Sima?
#
# DATO CLAVE: los SFS de Sima cubren solo 3–10 millones de sitios
# (0,10–0,34 % del genoma). Eso es una profundidad efectiva de ~0,001–0,003x:
# casi todos los sitios cubiertos tienen UNA lectura. Con una sola lectura un
# heterocigoto y un homocigoto derivado son indistinguibles, así que la H
# puede no ser identificable.
#
# DISEÑO: se toma Vindija (H conocida con este pipeline a cobertura completa:
# 0,001277; publicada: 1,6e-4), se submuestrea a profundidades decrecientes
# hasta igualar el número de sitios de Sima, y se recalcula H con el pipeline
# IDÉNTICO. Si H se mantiene estable al bajar la cobertura, el método es
# válido a la cobertura de Sima. Si deriva, PopSize no es viable tal como
# está planteado.
#
# USO (en una instancia EC2 con el rol SIMA-S3-Instance-Profile):
#   aws s3 ls s3://sima-egarmo-2026/bams/          # localizar el BAM de Vindija
#   export VINDIJA_S3=s3://sima-egarmo-2026/bams/<vindija>.bam
#   bash downsample_vindija.sh
#
# Resultados: s3://sima-egarmo-2026/popsize/downsample_<fecha>/
# Autor: E. García-Morán · preparado con Claude · 2026-10-28
# =============================================================================
set -euo pipefail

BUCKET="sima-egarmo-2026"
REGION="eu-west-1"
VINDIJA_S3="${VINDIJA_S3:?Define VINDIJA_S3=s3://.../vindija.bam (ver 'aws s3 ls s3://sima-egarmo-2026/bams/')}"

# Profundidades objetivo (x). Las tres centrales igualan a Sima:
#   molar_L35 ~0,0010x · femurXIII ~0,0023x · femur_fragment ~0,0034x
TARGETS="${TARGETS:-0.0010 0.0023 0.0034 0.01 0.1 1.0}"
SH_MATCHED="0.0010 0.0023 0.0034"   # en estas se hacen réplicas
REPS="${REPS:-3}"

# Filtros IDÉNTICOS a los de Sima (results/het/*_notrans.arg)
ANGSD_FILTERS="-doSaf 1 -GL 1 -minMapQ 30 -minQ 20 -noTrans 1 -checkBamHeaders 0"

THREADS=$(nproc)
WORK=/tmp/downsample
TS=$(date +%Y%m%d_%H%M%S)
OUT_S3="s3://${BUCKET}/popsize/downsample_${TS}"
mkdir -p "$WORK"/{ref,bam,saf,sfs}
cd "$WORK"
LOG="$WORK/downsample_${TS}.log"
exec > >(tee -a "$LOG") 2>&1
log() { echo "[$(date '+%H:%M:%S')] $*"; }
sync_s3() { aws s3 sync "$WORK/sfs" "$OUT_S3/sfs" --region "$REGION" --quiet || true
            aws s3 cp "$LOG" "$OUT_S3/" --region "$REGION" --quiet || true; }
trap sync_s3 EXIT

# ── 1. Dependencias ──────────────────────────────────────────────────────────
log "1. Dependencias"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq samtools wget gzip bc > /dev/null
command -v aws >/dev/null || { log "ERROR: falta aws cli"; exit 1; }

log "   ANGSD 0.941 precompilado desde S3"
aws s3 cp "s3://${BUCKET}/tools/angsd_compiled_ubuntu22.tar.gz" . --region "$REGION" --quiet
tar xzf angsd_compiled_ubuntu22.tar.gz
ANGSD_DIR=$(dirname "$(find "$WORK" -type f -name angsd -perm -u+x | head -1)")
export PATH="$ANGSD_DIR:$ANGSD_DIR/misc:$PATH"
HTS_LIB=$(find "$WORK" -type d -path '*htslib_install/lib' | head -1 || true)
[ -n "$HTS_LIB" ] && export LD_LIBRARY_PATH="$HTS_LIB:${LD_LIBRARY_PATH:-}"
angsd 2>&1 | head -2 || true
command -v realSFS >/dev/null || { log "ERROR: realSFS no encontrado"; exit 1; }

# ── 2. BAM de Vindija: cabecera y nomenclatura ───────────────────────────────
log "2. Cabecera del BAM de Vindija: $VINDIJA_S3"
aws s3 cp "$VINDIJA_S3" bam/vindija_full.bam --region "$REGION" --quiet
samtools index -@ "$THREADS" bam/vindija_full.bam
FIRST_SN=$(samtools view -H bam/vindija_full.bam | awk -F'\t' '/^@SQ/{sub("SN:","",$2); print $2; exit}')
if [[ "$FIRST_SN" == chr* ]]; then PREFIX="chr"; else PREFIX=""; fi
log "   Cromosomas con prefijo '${PREFIX}' (primer contig: $FIRST_SN)"

# Solo autosomas 1–22, para todos los niveles
: > autosomes.rf
for i in $(seq 1 22); do echo "${PREFIX}${i}" >> autosomes.rf; done

# ── 3. Referencia hg19 con la misma nomenclatura que el BAM ─────────────────
log "3. Referencia hg19 (UCSC), autosomas, nomenclatura del BAM"
wget -q https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz -O ref/hg19.fa.gz
gunzip -f ref/hg19.fa.gz
samtools faidx ref/hg19.fa
samtools faidx ref/hg19.fa $(sed 's/^/chr/; s/^chrchr/chr/' autosomes.rf) > ref/auto.fa
[ -z "$PREFIX" ] && sed -i 's/^>chr/>/' ref/auto.fa
rm ref/hg19.fa ref/hg19.fa.fai
samtools faidx ref/auto.fa
REF=ref/auto.fa

# ── 4. Profundidad efectiva de Vindija con los filtros del pipeline ──────────
log "4. Profundidad efectiva de Vindija (chr21, MAPQ>=30, BQ>=20)"
CHR21="${PREFIX}21"
D_FULL=$(samtools depth -a -Q 30 -q 20 -r "$CHR21" bam/vindija_full.bam \
         | awk '{s+=$3; n++} END{printf "%.4f", s/n}')
log "   Profundidad media en $CHR21: ${D_FULL}x"
echo -e "nivel\tprofundidad_objetivo\tfraccion\treplica\tsitios\tSFS0\tSFS1\tSFS2\tH_global" > sfs/summary.tsv

# ── 5. Submuestreo + ANGSD + realSFS ────────────────────────────────────────
run_level () {  # $1 = profundidad objetivo, $2 = réplica (semilla)
  local tgt=$1 rep=$2
  local frac; frac=$(echo "scale=10; $tgt / $D_FULL" | bc -l)
  if (( $(echo "$frac >= 1" | bc -l) )); then
    log "   [x$tgt] la profundidad completa ($D_FULL) es menor que el objetivo; se omite"; return
  fi
  local tag="d${tgt}_r${rep}"
  local seed=$((rep + 41))
  # samtools -s SEED.FRACCION  (p. ej. 42.0000700)
  local sarg; sarg=$(printf "%d.%s" "$seed" "$(printf "%.10f" "$frac" | cut -d. -f2)")
  log "   [$tag] fracción=$frac (samtools -s $sarg)"
  samtools view -@ "$THREADS" -b -s "$sarg" -o "bam/${tag}.bam" bam/vindija_full.bam
  samtools index "bam/${tag}.bam"
  angsd -i "bam/${tag}.bam" -ref "$REF" -anc "$REF" -rf autosomes.rf \
        $ANGSD_FILTERS -P "$THREADS" -out "saf/${tag}" > "saf/${tag}.angsd.log" 2>&1
  realSFS "saf/${tag}.saf.idx" -P "$THREADS" > "sfs/${tag}.sfs" 2> "sfs/${tag}.realSFS.log"
  cp "saf/${tag}.arg" sfs/
  awk -v t="$tgt" -v f="$frac" -v r="$rep" \
      '{a+=$1; b+=$2; c+=$3} END{n=a+b+c;
        printf "d%s\t%s\t%s\t%s\t%.0f\t%.3f\t%.3f\t%.3f\t%.6f\n", t, t, f, r, n, a, b, c, b/n}' \
      "sfs/${tag}.sfs" | tee -a sfs/summary.tsv
  rm -f "bam/${tag}.bam" "bam/${tag}.bam.bai" "saf/${tag}".saf.*
  sync_s3
}

log "5. Submuestreo"
for tgt in $TARGETS; do
  if [[ " $SH_MATCHED " == *" $tgt "* ]]; then
    for r in $(seq 1 "$REPS"); do run_level "$tgt" "$r"; done
  else
    run_level "$tgt" 1
  fi
done

# ── 6. Resumen ───────────────────────────────────────────────────────────────
log "6. RESUMEN"
log "   Referencias: Vindija pipeline completo H=0.001277 · Vindija publicada (Prüfer 2017) H=1.6e-4"
log "   Sima (H bruta): femurXIII 0.002058 (6.49M sitios) · femur_fragment 0.001503 (9.83M) · molar_L35 0.001740 (2.99M)"
column -t sfs/summary.tsv
cat <<'EOF'

INTERPRETACIÓN
  · H estable (≈0.0013) en todos los niveles → el pipeline es válido a baja
    cobertura; la comparación Sima/Vindija es interpretable.
  · H cambia al bajar la profundidad → la H de Sima es un artefacto de la
    cobertura; PopSize no es viable con heterozigosidad de un solo individuo.
  · Compararlo con Sima: si Vindija a ~0.002x da H ≈ 0.0015–0.0021, los
    valores de Sima son lo que el método produce a esa cobertura, sea cual
    sea la diversidad real.
EOF
log "Resultados en $OUT_S3"
