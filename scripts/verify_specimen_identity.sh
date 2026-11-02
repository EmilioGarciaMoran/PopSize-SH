#!/usr/bin/env bash
# =============================================================================
# verify_specimen_identity.sh — ¿Está cada BAM hg38 correctamente etiquetado?
#
# MOTIVO: el 28-oct se descubrió que bams/Sima_FemurXIII.hg19.sorted.bam era en
# realidad el incisivo AT-5482 (ERR995358). Si el error vino de la descarga
# original, los BAM hg38 de PopSize podrían arrastrarlo.
#
# IMPORTANTE: esto NO afecta a la retractación. El argumento de cobertura es
# independiente de las etiquetas: una lectura por sitio es una lectura por
# sitio, se llame el espécimen como se llame. Esto es para dejar el registro
# correcto, no para revisar la conclusión.
#
# TRES COMPROBACIONES:
#   A. Tabla oficial de ENA: qué accesión corresponde a qué espécimen.
#   B. Cabeceras de los BAM: a veces guardan el fichero de origen.
#   C. Solapamiento de nombres de lectura (decisiva): los nombres sobreviven
#      al realineamiento, así que un BAM hg38 y su original hg19 de ENA
#      comparten casi todos los nombres, y con los demás no comparten ninguno.
#
# USO:  bash verify_specimen_identity.sh
# Necesita: samtools, curl, awk. Descarga ~200 MB de ENA.
# =============================================================================
set -euo pipefail

W="$HOME/PopSize/verify_ids"
BUCKET="sima-egarmo-2026"
SPECIMENS="femurXIII femur_fragment incisor molar_L35 scapula"
NSAMPLE="${NSAMPLE:-20000}"     # nombres de lectura a muestrear por BAM hg38
mkdir -p "$W"/{hg38,ena,names}
cd "$W"
log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── A. Tabla oficial de ENA ─────────────────────────────────────────────────
log "A. Tabla de ENA para PRJEB10597"
curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB10597&result=read_run&fields=run_accession,sample_title,read_count,base_count,submitted_ftp&format=tsv" \
  | tee ena_runs.tsv | column -t -s $'\t'
echo
log "   ^ 'sample_title' es la fuente de verdad sobre qué espécimen es cada accesión."

# ── B. Cabeceras de los BAM hg38 ────────────────────────────────────────────
log "B. Cabeceras de los BAM hg38 (buscando el fichero de origen)"
for SP in $SPECIMENS; do
  F="hg38/${SP}.bam"
  if [ ! -s "$F" ]; then
    aws s3 cp "s3://${BUCKET}/sima_hg38/results/bam_rescaled/${SP}.rescaled.bam" "$F" --quiet
    aws s3 cp "s3://${BUCKET}/sima_hg38/results/bam_rescaled/${SP}.rescaled.bam.bai" "${F}.bai" --quiet || samtools index "$F"
  fi
  echo "--- ${SP} ---"
  samtools view -H "$F" | grep -E '^@(RG|PG|CO)' | cut -c1-200 || echo "  (sin @RG/@PG/@CO)"
  echo "  lecturas: $(samtools view -c "$F")"
done
echo

# ── C. Solapamiento de nombres de lectura ───────────────────────────────────
log "C. Descargando los BAM originales de ENA (hg19)"
awk -F'\t' 'NR>1 && $5!="" {split($5,a,";"); print $1"\t"a[1]}' ena_runs.tsv \
  | while IFS=$'\t' read -r RUN URL; do
      OUT="ena/${RUN}.bam"
      [ -s "$OUT" ] || { log "   $RUN"; curl -s -o "$OUT" "https://${URL#ftp://}"; }
    done
ls -lh ena/*.bam

log "   Extrayendo nombres de lectura de los originales de ENA"
for B in ena/*.bam; do
  RUN=$(basename "$B" .bam)
  [ -s "names/${RUN}.txt" ] || samtools view "$B" | cut -f1 | sort -u > "names/${RUN}.txt"
  echo "   ${RUN}: $(wc -l < "names/${RUN}.txt") nombres únicos"
done

log "   Comparando cada BAM hg38 contra cada original de ENA"
printf "\n%-16s" "hg38 \\ ENA"
for N in names/*.txt; do printf "%12s" "$(basename "$N" .txt)"; done; echo
for SP in $SPECIMENS; do
  samtools view "hg38/${SP}.bam" | cut -f1 | shuf -n "$NSAMPLE" 2>/dev/null | sort -u > "names/_q_${SP}.txt"
  Q=$(wc -l < "names/_q_${SP}.txt")
  printf "%-16s" "$SP"
  for N in names/*.txt; do
    case "$(basename "$N")" in _q_*) continue;; esac
    HIT=$(comm -12 "names/_q_${SP}.txt" "$N" | wc -l)
    printf "%11s%%" "$(awk -v h="$HIT" -v q="$Q" 'BEGIN{printf "%.1f", 100*h/q}')"
  done
  echo
done

cat <<'EOF'

CÓMO LEER LA MATRIZ
  Cada fila es un BAM hg38; cada columna, un original de ENA. El valor es el
  porcentaje de nombres de lectura muestreados que aparecen en ese original.

  · Una celda alta (>90 %) por fila, y el resto a cero → etiquetas correctas si
    la celda alta cae en la accesión que la tabla A asigna a ese espécimen.
  · La celda alta en otra accesión → ese BAM es otro espécimen. Anota la
    correspondencia real y corrige README, SFS y figuras.
  · Todo a cero → los nombres de lectura se reescribieron en el procesado;
    entonces la vía es comparar recuentos de lecturas contra la columna
    read_count de la tabla A.
EOF
