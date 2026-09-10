library(ggplot2)
library(gridExtra)
library(grid)

specs <- c("femurXIII", "molar_L35", "femur_fragment", "scapula")
cols  <- c("#185FA5", "#185FA5", "#854F0B", "#0F6E56")

# Panel A: H calibrada con IC95%
h_data <- data.frame(
  specimen = factor(specs, levels=specs),
  H    = c(0.001183, 0.001207, 0.000925, 0.000590),
  lo   = c(0.001093, 0.001164, 0.000744, 0.000565),
  hi   = c(0.001236, 0.001249, 0.001082, 0.000612),
  col  = cols
)

pA <- ggplot(h_data, aes(x=specimen, y=H, color=col)) +
  geom_point(size=4) +
  geom_errorbar(aes(ymin=lo, ymax=hi), width=0.2, linewidth=0.6) +
  geom_hline(yintercept=0.000701, color="#A32D2D", linetype="dashed", linewidth=0.5) +
  annotate("text", x=4.4, y=0.000720, label="Vindija", color="#A32D2D",
           size=2.8, hjust=1, fontface="italic") +
  scale_color_identity() +
  scale_y_continuous(limits=c(0.0004, 0.0014),
                     labels=function(x) sprintf("%.4f", x)) +
  labs(title="A. Calibrated heterozygosity (H)",
       subtitle="Bootstrap 95% CI (n=100, 5 Mb blocks)",
       y="H (calibrated)", x=NULL) +
  theme_classic(base_size=11) +
  theme(plot.background=element_rect(fill="white", color=NA),
        plot.title=element_text(size=11, face="bold"),
        plot.subtitle=element_text(size=8, color="grey40"),
        axis.text.x=element_text(angle=25, hjust=1, size=9))

# Panel B: FST (distancia media al resto)
fst_mat <- matrix(c(
  0,     0.041, 0.302, 0.123,
  0.041, 0,     0.284, 0.241,
  0.302, 0.284, 0,     0.285,
  0.123, 0.241, 0.285, 0
), 4, 4, byrow=TRUE)
rownames(fst_mat) <- colnames(fst_mat) <- specs

mean_fst <- rowMeans(fst_mat)

fst_data <- data.frame(
  specimen = factor(specs, levels=specs),
  fst_mean = mean_fst,
  col = cols
)

pB <- ggplot(fst_data, aes(x=specimen, y=fst_mean, fill=col)) +
  geom_col(width=0.6, alpha=0.8) +
  scale_fill_identity() +
  labs(title=expression(paste("B. Mean pairwise ", F[ST])),
       subtitle="Average genetic distance to other SH specimens",
       y=expression(paste("Mean ", F[ST])), x=NULL) +
  scale_y_continuous(limits=c(0, 0.35)) +
  theme_classic(base_size=11) +
  theme(plot.background=element_rect(fill="white", color=NA),
        plot.title=element_text(size=11, face="bold"),
        plot.subtitle=element_text(size=8, color="grey40"),
        axis.text.x=element_text(angle=25, hjust=1, size=9))

# Panel C: Branch shortening (derived fraction)
bs_data <- data.frame(
  specimen = factor(specs, levels=specs),
  derived  = c(0.00110710, 0.00110084, 0.00097869, 0.00053725),
  col = cols
)
bs_data$ratio <- bs_data$derived / min(bs_data$derived)

pC <- ggplot(bs_data, aes(x=specimen, y=derived, color=col)) +
  geom_point(size=4) +
  geom_segment(aes(x=specimen, xend=specimen, y=0, yend=derived),
               linewidth=0.8) +
  scale_color_identity() +
  annotate("text", x=1, y=0.00115,
           label="genetically\nmore recent", size=2.5,
           color="grey50", fontface="italic", lineheight=0.85) +
  annotate("text", x=4, y=0.00040,
           label="genetically\nmore ancient", size=2.5,
           color="grey50", fontface="italic", lineheight=0.85) +
  geom_text(aes(label=sprintf("%.2fx", ratio), y=derived+0.00005),
            size=3, show.legend=FALSE, fontface="bold") +
  labs(title="C. Branch shortening (derived allele fraction)",
       subtitle="Higher = more derived mutations = genetically younger",
       y="Derived allele fraction", x=NULL) +
  scale_y_continuous(limits=c(0, 0.0013),
                     labels=function(x) sprintf("%.5f", x)) +
  theme_classic(base_size=11) +
  theme(plot.background=element_rect(fill="white", color=NA),
        plot.title=element_text(size=11, face="bold"),
        plot.subtitle=element_text(size=8, color="grey40"),
        axis.text.x=element_text(angle=25, hjust=1, size=9))

# Combine
title_grob <- textGrob(
  "Three independent estimators converge: Sima de los Huesos specimens (~430 ka)",
  gp=gpar(fontsize=13, fontface="bold"))

subtitle_grob <- textGrob(
  paste0("Blue = Cluster A (MIS 11 interglacial)  |  ",
         "Green = Cluster B (MIS 12 glacial)  |  ",
         "Brown = Outlier"),
  gp=gpar(fontsize=9, col="grey40"))

p_combined <- arrangeGrob(
  title_grob, subtitle_grob,
  pA, pB, pC,
  nrow=5,
  heights=c(0.06, 0.04, 1, 1, 1)
)

ggsave("~/PopSize/results/three_panel_convergence.png",
       p_combined, width=8, height=12, dpi=300, bg="white")
ggsave("~/PopSize/results/three_panel_convergence.pdf",
       p_combined, width=8, height=12, device="pdf", bg="white")

cat("✓ Figura 3 paneles guardada\n")
