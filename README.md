# PopSize — Tamaño Poblacional Efectivo en Homínidos Arcaicos
**Autor:** Emilio García-Morán — emilio.garcia.moran@uva.es  
**ORCID:** 0000-0002-2487-6686  
**Universidad de Valladolid**  
**Período:** Mayo 2026  
**Estado:** ✅ Manuscrito enviado · ⏳ Revisión editorial pendiente

---

## Pregunta científica

¿Cuándo ocurrió el cuello de botella demográfico neandertal?

Si Ne(SH) >> Ne(Vindija) → el colapso ocurrió **después de 430 ka**  
Si Ne(SH) ≈ Ne(Vindija) → el colapso es **anterior a 430 ka**

---

## Datos

| Tipo | Fuente | Accesión |
|------|--------|----------|
| BAMs Sima de los Huesos (5 especímenes, hg38+mapDamage) | Meyer et al. 2016 | PRJEB10597 |
| BAM Vindija 33.19 (calibración, hg19) | Prüfer et al. 2014 | ERR1025630 |
| Infraestructura | AWS S3 eu-west-1 | s3://sima-egarmo-2026 |

**Cobertura media SH:** ~1.18× genome-wide  
**Pipeline:** AdapterRemoval → BWA-MEM (-k16) → Picard MarkDuplicates → mapDamage 2.2.1 (--rescale, MCMC) → hg38

---

## Resultados principales

### Heterozigosidad bootstrap (ANGSD v0.941, transversiones, n=100 réplicas)

| Espécimen | H calibrada | IC 95% | Ne proxy |
|-----------|------------:|--------|----------:|
| femurXIII | 0.001183 | 0.001093–0.001236 | ~23,710 |
| femur_fragment | 0.000925 | 0.000744–0.001082 | ~18,551 |
| molar_L35 | 0.001207 | 0.001164–0.001249 | ~24,207 |
| scapula | 0.000590 | 0.000565–0.000612 | ~11,825 |
| **Media SH** | **0.000977** | 0.000577–0.001241 | **~19,571** |
| Vindija 33.19* | 0.000701 | — | ~3,000** |

\* Mismo pipeline, hg19. Factor de inflación: 1.82×  
\*\* Valor publicado Prüfer et al. 2014

**Ratio Ne(SH)/Ne(Vindija): 1.39× (rango conservador 1.15×–1.65×)**  
→ El cuello de botella neandertal ocurrió **después de 430 ka**

### Hallazgo secundario
Heterogeneidad interna significativa entre especímenes (IC95% no solapantes entre scapula y molar_L35/femurXIII), consistente con depósito diacrónico de la Sima de los Huesos.

---

## Métodos

```bash
# ANGSD heterozigosidad (transversiones only)
angsd -i BAM -ref hg38.fa -anc hg38.fa \
      -doSaf 1 -GL 1 -P 8 \
      -minMapQ 30 -minQ 20 -noTrans 1 \
      -checkBamHeaders 0 -out results/het/SPECIMEN

# SFS + bootstrap (100 réplicas, bloques 5Mb)
realSFS SPECIMEN.saf.idx -bootstrap 100 -tole 1e-6 > SPECIMEN_boot.sfs

# Calibración: H_cal = H_raw / 1.82
```

**Software:** ANGSD v0.941 · realSFS · ROHan v2.3 · mapDamage 2.2.1 · R 4.x  
**Infraestructura:** AWS EC2 c5.2xlarge Spot, eu-west-1

---

## Manuscrito

**Título:** Genomic heterogeneity among Sima de los Huesos hominins suggests demographic structure and potentially diachronic accumulation  
**Revista:** Journal of Human Evolution — Short Communication  
**Estado:** Borrador v3 enviado a equipo Atapuerca (Bermúdez de Castro + Martínez) — Mayo 2026  
**APC:** Cubierto por acuerdo CRUE-CSIC UVa–Elsevier

---

## Limitaciones

- Cobertura 1.18× impide ROH fiables (mín. ~5× requerido)
- Ne values = heterozygosity-derived proxies, no Ne real
- Argumento diacrónico sugerente, no concluyente
- Calibración Vindija aproximada (hg19 vs hg38)

---

## Próximos pasos

- [ ] Respuesta equipo Atapuerca → posible coautoría
- [ ] Decisión editorial AJBA
- [ ] **ProteomaSH** — variantes funcionales in silico

---

## Referencias clave

- Meyer et al. (2016) *Nature* 531:504–507 — PRJEB10597
- Prüfer et al. (2014) *Nature* 505:43–49
- Mafessoni et al. (2020) ROHan. *PNAS* 117:14318–14326
- Massilani et al. (2026) *PNAS* 123:e2534576123
- Korneliussen et al. (2014) ANGSD. *BMC Bioinformatics* 15:356
