# PopSize — Effective Population Size in Sima de los Huesos Hominins (~430 ka)
**Author:** Emilio García-Morán — emilio.garcia.moran@uva.es  
**ORCID:** 0000-0002-2487-6686  
**Universidad de Valladolid**  
**Updated:** September 2026  
**GitHub:** github.com/EmilioGarciaMoran/PopSize-SH

---

## Project status

| Item | Status |
|---|---|
| AJBA paper (mito-nuclear) | ❌ Withdrawn — pursuing collaboration with Atapuerca team |
| PopSize v6 | 📝 Ready to send to Carretero/Martínez (CENIEH) |
| Calibration | ✅ Validated: Vindija 1.824x + Denisova 1.814x = 1.82x ± 0.005 SD |
| Collaboration | ⏳ Pending stratigraphic data from Atapuerca team |

---

## Scientific question

Did the Neandertal demographic bottleneck predate or postdate 430 ka?

**Result:** Ne(SH) ~19,571 vs Ne(Vindija) ~3,000 → ratio 1.39x → bottleneck postdates 430 ka.

---

## Key results

### Calibrated heterozygosity (ANGSD v0.941, transversions, n=100 bootstrap)

| Specimen | H calibrated | 95% CI | Ne estimate | SD |
|---|---|---|---|---|
| femurXIII | 0.001183 | 0.001093–0.001236 | ~23,710 | 0.000073 |
| femur_fragment | 0.000925 | 0.000744–0.001082 | ~18,551 | 0.000187 |
| molar_L35 | 0.001207 | 0.001164–0.001249 | ~24,207 | 0.000068 |
| scapula | 0.000590 | 0.000565–0.000612 | ~11,825 | 0.000020 |
| **SH mean** | **0.000977** | 0.000577–0.001241 | **~19,571** | — |
| Vindija 33.19* | 0.000701 | — | ~3,000** | — |

\* Same pipeline. \*\* Published Ne (Prüfer et al. 2014).

### Calibration empirically validated

| Genome | H pipeline | H published | Factor | Coverage |
|---|---|---|---|---|
| Vindija 33.19 | 0.001277 | 0.000700 | 1.824x | ~30x |
| Denisova | 0.000907 | 0.000500 | 1.814x | ~30x |
| **Mean** | — | — | **1.82x ± 0.005** | — |
| Ust-Ishim | 0.019818 | 0.001000 | 19.8x | ~42x |

Ust-Ishim excluded: modern human BAM without rescaling, factor biologically implausible.

### Pairwise FST (ANGSD v0.940, transversions)

| | femurXIII | molar_L35 | scapula | femur_fragment |
|---|---|---|---|---|
| femurXIII | — | **0.041** (9,437) | 0.123 (17,461) | 0.302 (29,045) |
| molar_L35 | 0.041 | — | 0.241 (11,563) | 0.284 (18,680) |
| scapula | 0.123 | 0.241 | — | 0.285 (27,592) |
| femur_fragment | 0.302 | 0.284 | 0.285 | — |

Shared transversion sites in parentheses.

**Cluster A (MIS 11 — interglacial):** femurXIII + molar_L35 (FST=0.041, H high)  
**Cluster B (MIS 12 — glacial):** scapula (H low)  
**Outlier:** femur_fragment (FST ~0.30 vs all)

### Comparison with Bossoms Mesa 2026 (Nature)

Late Neandertals (12 specimens, multiple sites, ~40-54 ka):
- IBS distance range: 0.042–0.073 (pseudo-haploid genotypes)
- Genetically homogeneous

SH (4 specimens, single site, ~430 ka):
- FST range: 0.041–0.302
- Much more internally heterogeneous than 12 late Neandertals from multiple sites

### Branch shortening — DISCARDED

Derived allele fraction analysis was attempted but discarded because scapula shows SFS[2]=0 (zero homozygous derived sites in 6.3M sites) — biologically implausible, likely ascertainment artifact at very low coverage. This precludes reliable derived-fraction comparisons.

### ROHan — NOT INTERPRETABLE at 1.18x

Mean p(ROH) 0.033–0.050, no window >0.50. Discarded.

### ArchaicPlus panel in silico — NOT VIABLE

2.28M SNPs from Bossoms Mesa 2026 require hybridization capture. At 1.18x shotgun: intersection = 3-4 sites per specimen. Not viable without wet lab.

---

## Manuscript v6

**Title:** Genomic heterogeneity among Sima de los Huesos hominins suggests demographic structure and potentially diachronic accumulation  
**Journal:** Journal of Human Evolution — Short Communication  
**Elements:** 2 figures, 3 tables, 12 references  
**No acknowledgements** (pending coauthorship decisions)

**Figures:**
- Figure 1: Violin plots bootstrap H calibrated (`violin_bootstrap_SH_v4.png`)
- Figure 2: FST dendrogram with MIS clusters (`fst_dendrogram_SH_v3.png`)

---

## Data locations

### S3: s3://sima-egarmo-2026 (eu-west-1)

| Path | Content |
|---|---|
| `sima_hg38/results/bam_rescaled/` | 5 SH BAMs hg38 + mapDamage (1.18x) |
| `eastwest/sima/ERR995357-361_sorted.bam` | 5 SH BAMs hg38 |
| `bams/Sima_FemurXIII.hg19.sorted.bam` | FemurXIII hg19 |
| `bams/Ust_Ishim_*.bam` (1.7GB) | Ust-Ishim hg19 |
| `bams/Denisova_*.bam` (5.9GB) | Denisova hg19 |
| `bams/Neandertal_*.bam` (1.7GB) | Vindija hg19 |
| `goyet/LowCoverages.{geno,snp,ind}` | ArchaicPlus panel 2.28M SNPs |
| `calibration/results_20260910/` | SFS Vindija + Denisova + Ust-Ishim |
| `tools/angsd_compiled_ubuntu22.tar.gz` | ANGSD 0.941 (107MB) |

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

### Local key files

```
~/PopSize/results/bootstrap/*_boot.sfs          ← bootstrap 100 reps × 4 specimens
~/PopSize/results/het/*_notrans.saf{.gz,.idx}    ← SAF files
~/PopSize/results/2dsfs_*.txt                    ← 2D-SFS for FST
~/PopSize/results/roh/*.hmmp.gz                  ← ROHan (not interpretable)
~/PopSize/results/violin_bootstrap_SH_v4.png     ← Figure 1
~/PopSize/results/fst_dendrogram_SH_v3.png       ← Figure 2
~/PopSize/results/heatmap_goyet_IBS.png          ← Goyet comparison
~/PopSize/results/heatmap_SH_FST.png             ← SH heatmap
~/PopSize/data/goyet/LowCoverages.{geno,snp,ind} ← ArchaicPlus panel
~/PopSize/data/goyet/GN1_chr22.vcf.gz            ← GN1 chr22 VCF
```

---

## Pending analyses

### Priority — for collaboration with Atapuerca team
- [ ] Stratigraphic assignment of specimens to MIS 12 vs MIS 11
- [ ] Correlation of H clusters with stratigraphic levels
- [ ] Faunal context per specimen level

### Methodological — next AWS session
- [ ] D-statistics specimen by specimen: D(SH_i, Vindija; D17, outgroup)
  - Needs: complete Vindija/D17 VCFs genome-wide (current ones only chr15, 438 variants)
  - Or: ANGSD -doAbbababa on hg19 BAMs from ENA
- [ ] admixfrog ancestry segments per chromosome
- [ ] GN1 full-genome H via ANGSD for direct calibration point

### For revised manuscript
- [ ] Bootstrap CI for FST (requested by DeepSeek)
- [ ] Process all on same assembly (hg19 or hg38 only)
- [ ] Null model: can drift + sequencing error in one population reproduce observed dispersion?

---

## Lessons learned

1. **Calibration factor 1.82x is robust** — validated across Vindija + Denisova independently
2. **Ust-Ishim excluded** — modern human BAM without rescaling gives factor 19.8x (artifact)
3. **ArchaicPlus panel not viable in silico** — requires hybridization capture, 3-4 sites at 1.18x
4. **SFS[2]=0 in scapula** — zero homozygous derived sites is ascertainment artifact, precludes derived-fraction analyses
5. **GN1 H_tv = 0.0000793 (chr22)** — much lower than Vindija published, confirms different H calculation methods across papers are not directly comparable
6. **Pseudo-haploid genotypes** (Goyet LowCoverages) have Het=0 by design — use IBS, not H

---

## Infrastructure

```
Bucket:    s3://sima-egarmo-2026 (eu-west-1)
Key:       ~/PopSize/aws/sima-key-2026.pem
Token:     ~/PopSizeToken.txt (GitHub)
AMI:       ami-0f27749973e2399b6 (Ubuntu 22.04)
Type:      c5.2xlarge Spot (~€0.10/h)
```

---

## References

- Meyer et al. (2016) Nuclear DNA SH. *Nature* 531:504–507 — PRJEB10597
- Prüfer et al. (2014) Vindija genome. *Nature* 505:43–49
- Bossoms Mesa et al. (2026) Late Neandertals. *Nature* 655:409–417
- Amadei et al. (2025) Genetic dilution model. *Sci. Reports* 15:38593
- Massilani et al. (2026) Altai Neandertal. *PNAS* 123:e2534576123
- Mafessoni et al. (2020) ROHan + Chagyrskaya. *PNAS* 117:14318–14326
- Meyer et al. (2012) Denisova genome. *Science* 338:222–226
- Fu et al. (2014) Ust-Ishim. *Nature* 514:445–449
- Korneliussen et al. (2014) ANGSD. *BMC Bioinformatics* 15:356
