# PopSize — Tamaño Poblacional Efectivo en Homínidos Arcaicos
# Proyecto 3 — Chat nuevo
# Autor: Emilio García-Morán — emilio.garcia.moran@uva.es
# ORCID: 0000-0002-2487-6686
# Fecha inicio: 17 Mayo 2026

## Contexto — de dónde viene esto

Durante el desarrollo del paper EastWestDM (Genome Medicine submission
8933a7cc-43ae-49d7-a8b1-ca460df4cfc8) se procesaron 5 especímenes de
Sima de los Huesos (430,000 ya) remapeados a hg38:

```
~/EastWestDM/results_sima_hg38/results/
  femurXIII_hg38_rescaled.bam
  incisor_hg38_rescaled.bam
  molar_L35_hg38_rescaled.bam
  scapula_hg38_rescaled.bam
  femur_fragment_hg38_rescaled.bam
```

Pipeline: AdapterRemoval → BWA-MEM (-k16) → Picard MarkDuplicates →
mapDamage 2.2.1 (--rescale, MCMC) → hg38

Cobertura media: 1.18× genome-wide
Accesión original: PRJEB10597 (Meyer et al. 2016, Nature)

También disponibles:
- ~/EastWestDM/act3/Vindija_variants.vcf.gz    (Neandertal ~44 ka)
- ~/EastWestDM/act3/D17_variants.vcf.gz         (Denisovano ~50 ka)
- ~/EastWestDM/act3/Ust_variants.vcf.gz          (Humano moderno ~45 ka)

## La hipótesis central

La heterozigosidad genómica (H) es inversamente proporcional al tamaño
poblacional efectivo (Ne):

    θ = 4 × Ne × μ       (μ = 1.25×10⁻⁸ por sitio por generación)
    H ≈ θ / (1 + θ)

Los Neandertales tardíos (Vindija ~44 ka) tienen Ne muy bajo (~3,000)
— señal de cuello de botella severo post-430 ka.

Los Denisovanos tienen Ne aún menor (~1,500).

**Pregunta:** ¿Cuál era Ne en Sima de los Huesos hace 430,000 años?

Si Ne(SH) >> Ne(Vindija) → el cuello de botella neandertal ocurrió
ENTRE 430 ka y 44 ka — evento poblacional específico identificable.

Si Ne(SH) ≈ Ne(Vindija) → el cuello de botella es ANTERIOR a 430 ka
— origen más profundo de la reducción poblacional neandertal.

## Análisis previstos

### 1. Heterozigosidad directa (2-4 horas)
```bash
# Por espécimen — sitios con cobertura ≥3×
samtools mpileup -q 25 -Q 20 -r chr{1..22} BAM | \
awk '{hom+=($5~/^[.,]+$/); het+=1} END{print het/(hom+het)}'
```

### 2. Runs of Homozygosity (ROH)
ROH largos → Ne pequeño → endogamia / cuello de botella
Herramienta: plink --homozyg o ROHan (diseñado para ancient DNA)

### 3. PSMC (Pairwise Sequentially Markovian Coalescent)
Historia demográfica temporal de Ne
Requiere cobertura ≥10× — SH está al límite (1.18×)
Posiblemente aplicable solo a Vindija y D17

### 4. Comparación multiespecífica
| Espécimen | Edad | H esperada | Ne estimado | Fuente |
|---|---|---|---|---|
| Sima de los Huesos | 430 ka | ? | ? | Este estudio |
| Vindija Neandertal | 44 ka | ~0.0007 | ~3,000 | Prüfer 2014 |
| D17 Denisovano | ~50 ka | ~0.0005 | ~1,500 | Meyer 2012 |
| Ust'-Ishim | ~45 ka | ~0.0010 | ~7,000 | Fu 2014 |
| Humano moderno AFR | 0 ka | ~0.0013 | ~10,000 | gnomAD |

### 5. Relación filogenética SH-Neandertal-Denisovano
Meyer 2016 (Nature 531) muestra ADN nuclear SH más cercano a
Neandertales que a Denisovanos — pero con mitocondria más cercana
a Denisovanos (Meyer 2014, Nature 505).
¿El Ne de SH es consistente con ancestro común Neandertal/Denisovano?

## Software disponible / a instalar

```bash
micromamba activate geodata  # entorno Python/R existente

# Instalar si necesario:
micromamba install -c bioconda rohan plink samtools -y
pip install hapROH --break-system-packages
```

## Referencias clave

- Meyer M et al. (2016) Nuclear DNA from Sima de los Huesos.
  Nature 531:504-507. PRJEB10597
- Prüfer K et al. (2014) Neandertal genome. Nature 505:43-49
- Meyer M et al. (2012) Denisovan genome. Science 338:222-226
- Fu Q et al. (2014) Ust'-Ishim. Nature 514:445-449
- Schiffels S, Durbin R (2014) PSMC/MSMC. Nature Genetics 46:919-925
- Mafessoni F et al. (2020) ROHan. Genome Research 30:1104-1113

## Directorios

```
~/PopSize/
  data/          ← symlinks a BAMs de SH + VCFs arcaicos
  scripts/       ← scripts de análisis
  results/       ← outputs
  README.md      ← este archivo
```

## Target journal

- Nature Ecology & Evolution
- Current Biology
- PLOS Genetics

## Frase semilla para el nuevo chat

*"Los Neandertales tardíos eran una población pequeña y endogámica
que marchaba hacia la extinción demográfica desde mucho antes de que
llegaran los humanos modernos. ¿Eran ya pequeños en Atapuerca hace
430,000 años, o fue algo que ocurrió después?
Tenemos los BAMs. Calculemos."*

## Estado
- BAMs procesados: ✅ 5 especímenes SH en hg38
- Análisis heterozigosidad: ⏳ pendiente
- ROH: ⏳ pendiente
- PSMC: ⏳ pendiente (cobertura limitante)
- Paper: 💡 hipótesis lista
