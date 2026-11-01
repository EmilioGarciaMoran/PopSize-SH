# PopSize — Effective Population Size in Sima de los Huesos Hominins (~430 ka)
**Author:** Emilio García-Morán — emilio.garcia.moran@uva.es  
**ORCID:** 0000-0002-2487-6686  
**Universidad de Valladolid**  
**Updated:** 1 November 2026  
**GitHub:** github.com/EmilioGarciaMoran/PopSize-SH

---

## ⚠️ Conclusions retracted — 28 October 2026

**The conclusions of manuscript v6 do not hold and have been withdrawn by the author.** An internal audit found that the published Sima de los Huesos nuclear data (Meyer et al. 2016, ENA PRJEB10597) cannot support per-individual heterozygosity estimates at the coverage available. The manuscript was never submitted; it circulated only as a draft among a few colleagues, who have been informed.

The retracted results are kept below, clearly marked, rather than deleted — anyone checking this repository should be able to see what was claimed and why it failed.

**Why the estimates fail**

1. **Effective coverage is ~0.002×, not 1.18×.** Each specimen's SFS covers 3–10 million sites (0.10–0.34 % of the genome). Measured directly on the femurXIII BAM (`samtools depth -Q 30 -q 20`): 6,618,629 sites, **97.7 % of them with a single read**.
2. **At one read per site, heterozygosity is not identifiable.** Observing a heterozygote requires both alleles at the same position, i.e. ≥2 reads. With one read, a heterozygote and a derived homozygote produce the same observation, so SFS[1] and SFS[2] are not separable and the output is driven by the model, not the data. This is why scapula shows SFS[2] ≈ 0.
3. **Control experiment.** A genome of known coverage (Denisova chr1 BAM, 0.92× effective) was downsampled to Sima-matched depths and run through the identical pipeline, 3 replicates per level:

   | Coverage | Apparent H | SFS2 per Mb of sites |
   |---|---|---|
   | 0.92× (full) | 0.000839 | 513 |
   | 0.1× | 0.001401 | 20 |
   | 0.0034× (×3) | 0.001097–0.001289 | ~49 |
   | 0.0023× (×3) | 0.001054–0.001400 | ~57 |

   The same genome, changing nothing but coverage, yields an apparent H **~1.5× higher** (1.26–1.67×). That is the magnitude v6 attributed to SH over Vindija (1.39×, with Vindija measured at ~30×). Replicate-to-replicate scatter at matched coverage is ±15 %, comparable to the between-specimen differences the manuscript interpreted.

   Reproduce with `scripts/dell_chr1_test.sh` (branch `audit/downsample-vindija`).

4. **Calibration factor 1.82× has no basis.** The reference values used (Vindija 0.000700, Denisova 0.000500) do not match the published ones (1.6×10⁻⁴ and 1.8×10⁻⁴; Prüfer et al. 2017). With the published values the two factors would be ~8× and ~5× and would not agree. Calibration genomes were also processed on hg19 at ~30×, SH on hg38 at ~0.002×.

5. **The pseudo-haploid alternative lacks power.** Between-individual mismatch (one random read per individual at shared sites) is the only diversity measure compatible with single-read data. The three usable specimens share ~57,000 sites in total, where ~3 real differences are expected; power to detect a 40 % excess is 14 %, before accounting for sequencing error. ~890,000 shared sites would be needed for 80 % power.

**What would be needed:** targeted capture (ArchaicPlus-type panel, Bossoms Mesa et al. 2026), which both restores observable heterozygosity at enriched positions and makes the results directly comparable to late Neandertals at the same positions with the same statistic.

**Diachronic accumulation (MIS 12 / MIS 11)** reverts to an open stratigraphic question. The genetic data provide no evidence for it: the FST clusters rest on an uncorrected estimator (sample-size-corrected estimators — Reynolds, Hudson/Bhatia — give ≈0 or negative values), and "Cluster B" was the scapula alone, which carries substantial modern contamination.

Full audit, with per-item findings: see `claude/AUDITORIA_POPSIZE_2026-10-28.md` in the author's project notes.

---

## Project status

| Item | Status |
|---|---|
| AJBA paper (mito-nuclear) | ❌ Withdrawn — pursuing collaboration with Atapuerca team |
| PopSize v6 | ❌ **Conclusions retracted (28 Oct 2026)** — never submitted; collaborators informed |
| Calibration 1.82× | ❌ **Invalid** — reference values do not match Prüfer et al. 2017 |
| FST / MIS clusters | ❌ **Not supported** — uncorrected estimator; values not traceable to a script |
| Collaboration | ⏳ Open — targeted capture is the viable route |

---

## Scientific question

Did the Neandertal demographic bottleneck predate or postdate 430 ka?

**Status:** unanswerable with the published SH nuclear data. The question itself remains open and worth pursuing with capture data.

~~**Result:** Ne(SH) ~19,571 vs Ne(Vindija) ~3,000 → ratio 1.39x → bottleneck postdates 430 ka.~~ *(retracted — see above; the two Ne figures also came from incompatible estimators, H/(4μ(1−H)) vs PSMC)*

---

## Retracted results

*Kept for the record. None of the numbers in this section should be cited.*

### ❌ Calibrated heterozygosity (ANGSD v0.941, transversions, n=100 bootstrap)

Retracted: H is not identifiable at this coverage, and the 1.82× calibration is invalid.

| Specimen | H calibrated | 95% CI | Ne estimate | SD |
|---|---|---|---|---|
| femurXIII | 0.001183 | 0.001093–0.001236 | ~23,710 | 0.000073 |
| femur_fragment | 0.000925 | 0.000744–0.001082 | ~18,551 | 0.000187 |
| molar_L35 | 0.001207 | 0.001164–0.001249 | ~24,207 | 0.000068 |
| scapula | 0.000590 | 0.000565–0.000612 | ~11,825 | 0.000020 |
| **SH mean** | **0.000977** | 0.000577–0.001241 | **~19,571** | — |
| Vindija 33.19* | 0.000701 | — | ~3,000** | — |

\* Same pipeline. \*\* Published Ne (Prüfer et al. 2014) — a PSMC estimate, not comparable with the H-derived figures above.

### ❌ Calibration

Retracted: the "H published" column does not match Prüfer et al. 2017 (Vindija 1.6×10⁻⁴, Denisova 1.8×10⁻⁴). The pipeline H values themselves are reproducible from the SFS in S3.

| Genome | H pipeline | H "published" (wrong) | Factor | Coverage | Reference |
|---|---|---|---|---|---|
| Vindija 33.19 | 0.001277 | 0.000700 | 1.824x | ~30x | hg19 |
| Denisova | 0.000907 | 0.000500 | 1.814x | ~30x | hg19 |
| Ust-Ishim | 0.019818 | 0.001000 | 19.8x | ~42x | hg19 |

### ❌ Pairwise FST (ANGSD, transversions)

Retracted: not traceable to any script, and not reproduced by standard estimators. Nei's GST computed per site and averaged over polymorphic sites reproduces 4 of 6 values (±0.005) but not femurXIII–molar_L35 (0.121 vs 0.041) or femurXIII–scapula (0.171 vs 0.123) — the two that defined "Cluster A". Sample-size-corrected estimators give ≈0 or negative values throughout: with n=1 diploid per group at ~0.002×, no differentiation is detectable above within-individual noise.

| | femurXIII | molar_L35 | scapula | femur_fragment |
|---|---|---|---|---|
| femurXIII | — | 0.041 (9,437) | 0.123 (17,461) | 0.302 (29,045) |
| molar_L35 | 0.041 | — | 0.241 (11,563) | 0.284 (18,680) |
| scapula | 0.123 | 0.241 | — | 0.285 (27,592) |
| femur_fragment | 0.302 | 0.284 | 0.285 | — |

Shared transversion sites in parentheses.

~~**Cluster A (MIS 11 — interglacial):** femurXIII + molar_L35~~ · ~~**Cluster B (MIS 12 — glacial):** scapula~~ · ~~**Outlier:** femur_fragment~~

### ❌ Comparison with Bossoms Mesa 2026 (Nature)

Retracted on two counts: the SH FST values are not supported, and FST and IBS are different statistics that cannot be compared range-to-range.

### Branch shortening — discarded (correctly)

Discarded because scapula shows SFS[2]=0. The audit explains why: at single-read coverage the model assigns non-reference reads to the heterozygous class and essentially never to the derived-homozygous class. The decision to discard was right; the stated reason ("ascertainment artifact") was incomplete.

### ROHan — not interpretable

Mean p(ROH) 0.033–0.050, no window >0.50. Discarded. (The stated coverage of 1.18× was wrong; the real figure makes ROH detection hopeless by a wide margin.)

### ArchaicPlus panel in silico — not viable

2.28M SNPs from Bossoms Mesa 2026 require hybridization capture. On shotgun data the intersection is 3–4 sites per specimen. Not viable without wet lab — this conclusion stands, and points to the route that would work.

---

## Manuscript v6 — withdrawn

**Title:** Genomic heterogeneity among Sima de los Huesos hominins suggests demographic structure and potentially diachronic accumulation  
**Intended journal:** Journal of Human Evolution — Short Communication  
**Status:** never submitted; conclusions retracted 28 October 2026.

Figures `violin_bootstrap_SH_v4.png` and `fst_dendrogram_SH_v3.png` display retracted quantities.

---

## Data locations

### S3: s3://sima-egarmo-2026 (eu-west-1)

| Path | Content |
|---|---|
| `sima_hg38/results/bam_rescaled/` | 5 SH BAMs hg38 + mapDamage (~0.002x per specimen genome-wide; the earlier "1.18x" was wrong) |
| `eastwest/sima/ERR995357-361_sorted.bam` | 5 SH BAMs hg38 |
| `bams/Sima_incisor_AT5482.hg19.sorted.bam` | Incisor AT-5482 hg19 (ERR995358); previously misnamed Sima_FemurXIII.hg19.sorted.bam |
| `bams/Ust_Ishim_*.bam` (1.7GB) | Ust-Ishim hg19 — **~0.03x effective, not high coverage** |
| `bams/Denisova_*.bam` (5.9GB) | Denisova hg19 — **~0.92x effective on chr1, not ~30x** |
| `bams/Neandertal_*.bam` (1.7GB) | Vindija hg19 — **~0.028x effective, not high coverage** |
| `goyet/LowCoverages.{geno,snp,ind}` | ArchaicPlus panel 2.28M SNPs |
| `calibration/results_20260910/` | SFS Denisova + Ust-Ishim (hg19 — note: SH processed on hg38) |
| `popsize/results_final_20260522/het/` | SFS Vindija (hg19) |
| `tools/angsd_compiled_ubuntu22.tar.gz` | ANGSD 0.941 (107MB) |

The BAMs under `bams/` are `bwa mem` alignments from the February 2026 D-statistics work, restricted to chr1 and of low coverage. They are **not** the high-coverage archaic genomes and should not be used as such.

### ENA (hg19 original BAMs)

```
ERR995357 → femurXIII       ftp.sra.ebi.ac.uk/vol1/run/ERR995/ERR995357/femurXIII.L35MQ30.bam
ERR995358 → incisor          ftp.sra.ebi.ac.uk/vol1/run/ERR995/ERR995358/incisor.L35MQ30.bam
ERR995359 → scapula          ftp.sra.ebi.ac.uk/vol1/run/ERR995/ERR995359/scapula.L35MQ30.bam
ERR995360 → molar_L35        ftp.sra.ebi.ac.uk/vol1/run/ERR995/ERR995360/molar.L35MQ30.bam
ERR995361 → femur_fragment   ftp.sra.ebi.ac.uk/vol1/run/ERR995/ERR995361/femur_fragment.L35MQ30.bam
```

### Goyet GN1 (Bossoms Mesa 2026)

```
DOI: doi:10.17617/3.F9N73O (EDMOND Max Planck)
VCFs by chromosome: GovetQ56_1_final.uniq.L35MQ25.sorted.chr_X.vcf.gz
Local: ~/PopSize/data/goyet/GN1_chr22.vcf.gz (549MB)
Metadata: ~/PopSize/data/edmond_goyet.json
```

### Local key files (not in this repository)

```
~/PopSize/results/bootstrap/*_boot.sfs          ← bootstrap 100 reps × 4 specimens
~/PopSize/results/het/*_notrans.saf{.gz,.idx}    ← SAF files
~/PopSize/calib/chr1test/out/resumen.tsv         ← downsampling control, 28 Oct 2026
```

---

## Open work

### Viable route
- [ ] Assess feasibility of targeted capture (ArchaicPlus-type panel) on SH material or existing libraries, with a power calculation for the specimen count and depth considered achievable
- [ ] If capture data become available: per-individual heterozygosity at enriched positions, plus the same statistic as Bossoms Mesa et al. 2026 at the same positions

### Stratigraphy (Atapuerca team)
- [ ] Diachronic accumulation is an open stratigraphic question. If sufficient genetic data ever exist, the testable prediction is that specimens from different levels show more differentiation than specimens from the same level.

### Housekeeping
- [ ] Upload `results/bootstrap/*_boot.sfs` so Table 1 of v6 is reproducible from this repository
- [ ] Add contamination estimates (ANGSD `-doContam` or schmutzi) for all specimens
- [ ] Remove or justify the pool-seq step in `user_data_popsize.sh`; restrict to autosomes (the `CHROMS` variable is defined but never used)

---

## Lessons learned

1. **Check effective coverage before choosing an estimator.** The quantity that matters is reads per site, not reads per genome. At ~1 read per covered site, per-individual heterozygosity is not an observable.
2. **Control with a genome of known value.** Downsampling a known genome through the identical pipeline would have caught this before any manuscript existed. It took two hours.
3. **A calibration factor cannot rescue a non-identifiable quantity** — and reference values must be checked against the source paper, not carried over from notes.
4. **Compare like with like.** H against H, or Ne against Ne from the same estimator. Never an H-derived Ne against a PSMC Ne. Never FST against IBS.
5. **Hard-coded numbers in plotting scripts are a reproducibility failure** even when nothing is wrong with them. Here, four of six FST values could be reproduced after the fact and two could not.
6. **Ust-Ishim excluded** — modern human BAM without rescaling gives factor 19.8x (artifact). Correct call.
7. **Pseudo-haploid genotypes** (Goyet LowCoverages) have Het=0 by design — use IBS, not H.

---

## Infrastructure

```
Bucket:    s3://sima-egarmo-2026 (eu-west-1)
AMI:       ami-0f27749973e2399b6 (Ubuntu 22.04)
Type:      c5.2xlarge Spot (~€0.10/h)
```

---

## References

- Meyer et al. (2016) Nuclear DNA SH. *Nature* 531:504–507 — PRJEB10597
- Prüfer et al. (2014) Altai Neandertal genome. *Nature* 505:43–49
- Prüfer et al. (2017) Vindija 33.19 genome. *Science* 358:655–658
- Bossoms Mesa et al. (2026) Late Neandertals. *Nature* 655:409–417
- Massilani et al. (2026) Altai Neandertal. *PNAS* 123:e2534576123
- Mafessoni et al. (2020) ROHan + Chagyrskaya. *PNAS* 117:14318–14326
- Meyer et al. (2012) Denisova genome. *Science* 338:222–226
- Fu et al. (2014) Ust-Ishim. *Nature* 514:445–449
- Korneliussen et al. (2014) ANGSD. *BMC Bioinformatics* 15:356
