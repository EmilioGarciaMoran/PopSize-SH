#!/usr/bin/env bash
# =============================================================================
# dell_chr1_test.sh — Versión local (Dell) del test de viabilidad de PopSize
#
# Toma un genoma neandertal de alta cobertura (BAM de chr1 en S3), lo
# submuestrea hasta la cobertura de Sima (~0,002x) y calcula H con el pipeline
# IDÉNTICO al de PopSize (ANGSD -doSaf 1 -GL 1 -minMapQ 30 -minQ 20 -noTrans 1
# + realSFS; H = SFS[1]/total). Si H cambia al bajar la cobertura, las H de
# Sima son un artefacto del método.
#
# Orden: primero los niveles bajos (rápidos, los que importan); la cobertura
# completa va al final porque es la más lenta. Los resultados se van
# escribiendo en resumen.tsv a medida que salen.
#
# Uso:  bash dell_chr1_test.sh [s3://.../neandertal_chr1.bam]
# =============================================================================
set -euo pipefail

BAM_S3="${1:-s3://sima-egarmo-2026/bams/Neandertal_20260213_002151.bam}"
W="$HOME/PopSize/calib/chr1test"
THREADS=$(nproc)
TARGETS_REP="0.0023 0.0034"     # coberturas de femurXIII y femur_fragment
TARGETS_ONE="0.01 0.1 1.0"
REPS=3
mkdir -p "$W"/{tools,bam,ref,out}
cd "$W"
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── 1. ANGSD ────────────────────────────────────────────────────────────────
if ! command -v angsd >/dev/null; then
  if [ ! -x tools/angsd/angsd ]; then
    log "1. Compilando htslib + ANGSD desde GitHub (unos minutos)"
    sudo apt-get install -y -qq build-essential zlib1g-dev libbz2-dev liblzma-dev libcurl4-openssl-dev > /dev/null
    cd tools
    [ -d htslib ] || git clone -q --recursive https://github.com/samtools/htslib.git
    [ -d angsd ]  || git clone -q https://github.com/ANGSD/angsd.git
    (cd htslib && make -j"$THREADS" > /dev/null)
    (cd angsd && make HTSSRC=../htslib -j"$THREADS" > /dev/null)
    cd "$W"
  fi
  export PATH="$W/tools/angsd:$W/tools/angsd/misc:$PATH"
fi
log "1. ANGSD: $(command -v angsd)  ·  realSFS: $(command -v realSFS)"

# ── 2. BAM ──────────────────────────────────────────────────────────────────
if [ ! -s bam/full.bam ]; then
  log "2. Descargando $BAM_S3"
  aws s3 cp "$BAM_S3" bam/full.bam --quiet
  aws s3 cp "${BAM_S3}.bai" bam/full.bam.bai --quiet || samtools index -@ "$THREADS" bam/full.bam
fi
log "2. Cabecera (para saber qué individuo es):"
samtools view -H bam/full.bam | grep -E '^@(RG|PG|CO)' | head -8 || true
CH=$(samtools view -H bam/full.bam | awk -F'\t' '/^@SQ/{sub("SN:","",$2); print $2; exit}')
NSQ=$(samtools view -H bam/full.bam | grep -c '^@SQ')
log "   Contigs en cabecera: $NSQ · se usa: $CH"

# ── 3. Referencia hg19 del mismo cromosoma, con el mismo nombre ─────────────
if [ ! -s ref/ref.fa.fai ]; then
  log "3. Referencia hg19 chr1 (UCSC)"
  wget -q https://hgdownload.soe.ucsc.edu/goldenPath/hg19/chromosomes/chr1.fa.gz -O ref/chr1.fa.gz
  gunzip -c ref/chr1.fa.gz | sed "1s/^>.*/>${CH}/" > ref/ref.fa
  samtools faidx ref/ref.fa
fi

# ── 4. Profundidad efectiva con los filtros del pipeline (ventana de 10 Mb) ─
D=$(samtools depth -a -Q 30 -q 20 -r "${CH}:50000001-60000000" bam/full.bam \
    | awk '{s+=$3; n++} END{printf "%.4f", s/n}')
log "4. Profundidad efectiva (MAPQ>=30, BQ>=20): ${D}x"

echo -e "nivel\treplica\tprofundidad_obj\tsitios\tSFS0\tSFS1\tSFS2\tH" > out/resumen.tsv

run () {  # $1 profundidad objetivo ("full" = sin submuestrear), $2 réplica
  local tgt=$1 rep=$2 tag="${1}_r${2}" in=bam/full.bam
  if [ "$tgt" != "full" ]; then
    local frac; frac=$(awk -v t="$tgt" -v d="$D" 'BEGIN{printf "%.10f", t/d}')
    if awk -v f="$frac" 'BEGIN{exit !(f>=1)}'; then log "   [$tag] objetivo >= profundidad real; se omite"; return; fi
    local sarg; sarg="$((rep + 41)).${frac#*.}"
    samtools view -@ "$THREADS" -b -s "$sarg" -o "bam/${tag}.bam" bam/full.bam
    samtools index "bam/${tag}.bam"
    in="bam/${tag}.bam"
  fi
  angsd -i "$in" -ref ref/ref.fa -anc ref/ref.fa -r "$CH" \
        -doSaf 1 -GL 1 -minMapQ 30 -minQ 20 -noTrans 1 -checkBamHeaders 0 \
        -P "$THREADS" -out "out/${tag}" > "out/${tag}.angsd.log" 2>&1
  realSFS "out/${tag}.saf.idx" -P "$THREADS" > "out/${tag}.sfs" 2> "out/${tag}.realSFS.log"
  awk -v l="$tgt" -v r="$rep" '{a+=$1;b+=$2;c+=$3} END{n=a+b+c;
      printf "%s\t%s\t%s\t%.0f\t%.1f\t%.1f\t%.1f\t%.6f\n", l, r, l, n, a, b, c, b/n}' \
      "out/${tag}.sfs" | tee -a out/resumen.tsv
  [ "$tgt" != "full" ] && rm -f "bam/${tag}.bam" "bam/${tag}.bam.bai"
  rm -f "out/${tag}".saf.gz "out/${tag}".saf.pos.gz
}

# ── 5. Niveles: primero los de Sima, al final la cobertura completa ────────
log "5. Submuestreo y ANGSD"
for t in $TARGETS_REP; do for r in $(seq 1 $REPS); do log "   nivel ${t}x, réplica $r"; run "$t" "$r"; done; done
for t in $TARGETS_ONE; do log "   nivel ${t}x"; run "$t" 1; done
log "   cobertura completa (${D}x) — la más lenta"
run full 1

# ── 6. Resumen ──────────────────────────────────────────────────────────────
log "6. RESUMEN"
column -t out/resumen.tsv
cat <<'EOF'

Referencias:
  Sima (H bruta, mismo pipeline): femurXIII 0.002058 · molar_L35 0.001740 · femur_fragment 0.001503
  Vindija genoma completo, mismo pipeline: 0.001277 · Vindija publicada (Prüfer 2017): 0.00016

Lectura:
  · Si H a 0.0023x / 0.0034x ≈ H a cobertura completa → el método aguanta a la cobertura de Sima.
  · Si H a 0.0023x / 0.0034x se aleja de la H completa (y se parece a las de Sima) →
    las H de Sima son lo que el método produce a esa cobertura: PopSize no es viable.
EOF
