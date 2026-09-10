library(ggplot2)
library(ggdendro)

specs <- c("femurXIII", "molar_L35", "scapula", "femur_fragment")

fst_mat <- matrix(0, 4, 4, dimnames=list(specs, specs))
fst_mat["femurXIII","molar_L35"]     <- fst_mat["molar_L35","femurXIII"]     <- 0.041
fst_mat["femurXIII","scapula"]        <- fst_mat["scapula","femurXIII"]        <- 0.123
fst_mat["femurXIII","femur_fragment"] <- fst_mat["femur_fragment","femurXIII"] <- 0.302
fst_mat["molar_L35","scapula"]        <- fst_mat["scapula","molar_L35"]        <- 0.241
fst_mat["molar_L35","femur_fragment"] <- fst_mat["femur_fragment","molar_L35"] <- 0.284
fst_mat["scapula","femur_fragment"]   <- fst_mat["femur_fragment","scapula"]   <- 0.285

# H calibrada y Ne proxy
h_vals <- c(femurXIII=0.001183, molar_L35=0.001207,
            scapula=0.000590, femur_fragment=0.000925)
ne_vals <- round(h_vals / (4 * 1.25e-8 * (1 - h_vals)))

# Clustering
dist_obj <- as.dist(fst_mat)
hc <- hclust(dist_obj, method="average")

ddata <- dendro_data(hc)

# Labels enriquecidos
lab_df <- label(ddata)
lab_df$specimen <- specs[match(lab_df$label, specs)]
lab_df$h_label <- sprintf("%s  (H=%.4f · Ne~%s)",
                           lab_df$label,
                           h_vals[lab_df$label],
                           format(ne_vals[lab_df$label], big.mark=","))

# Color por cluster
lab_df$color <- ifelse(lab_df$label %in% c("femurXIII","molar_L35"),
                        "#185FA5",
                 ifelse(lab_df$label == "scapula", "#0F6E56", "#854F0B"))

# Anotaciones de grupo
ann_df <- data.frame(
  x    = c(2.5,  3.0,  4.0),
  y    = c(0.06, 0.15, 0.31),
  lab  = c("Cluster A\n(período próspero)",
           "Cluster B\n(contracción)",
           "Outlier\n(origen distinto?)"),
  col  = c("#185FA5", "#0F6E56", "#854F0B")
)

p <- ggplot() +
  # Relleno de fondo por cluster
  annotate("rect", xmin=0.5, xmax=2.5, ymin=-0.075, ymax=0.07,
           fill="#E6F1FB", alpha=0.4) +
  annotate("rect", xmin=2.5, xmax=3.5, ymin=-0.075, ymax=0.07,
           fill="#E6F5F0", alpha=0.4) +
  annotate("rect", xmin=3.5, xmax=4.5, ymin=-0.075, ymax=0.07,
           fill="#F5EDE6", alpha=0.4) +

  # Dendrograma
  geom_segment(data=segment(ddata),
               aes(x=x, y=y, xend=xend, yend=yend),
               linewidth=1.0, color="grey30") +

  # Puntos en las hojas
  geom_point(data=lab_df,
             aes(x=x, y=0, color=color),
             size=5, show.legend=FALSE) +

  # Labels
  geom_text(data=lab_df,
            aes(x=x, y=-0.01, label=h_label, color=color),
            hjust=1, size=3.3, show.legend=FALSE,
            fontface="bold") +

  # Anotaciones de grupo
  geom_text(data=ann_df,
            aes(x=x, y=y, label=lab, color=col),
            size=3.0, fontface="italic", show.legend=FALSE,
            lineheight=0.85) +

  # Líneas verticales de grupo
  geom_vline(xintercept=2.5, linetype="dashed",
             color="grey60", linewidth=0.4) +
  geom_vline(xintercept=3.5, linetype="dashed",
             color="grey60", linewidth=0.4) +

  scale_color_identity() +
  scale_y_continuous(
    name = expression(F[ST]~"(genetic distance)"),
    limits = c(-0.09, 0.34),
    breaks = seq(0, 0.3, by=0.1),
    expand = c(0, 0)
  ) +
  scale_x_continuous(expand=c(0.15, 0.15)) +
  coord_flip() +

  labs(
    title = "Genetic structure among Sima de los Huesos specimens (~430 ka)",
    subtitle = expression(paste(
      "UPGMA clustering on pairwise ", F[ST],
      " matrix  \u00b7  ANGSD v0.940  \u00b7  transversions only  \u00b7  calibrated H"
    ))
  ) +

  theme_classic(base_size=12) +
  theme(
    plot.background  = element_rect(fill="white", color=NA),
    panel.background = element_rect(fill="white", color=NA),
    axis.text.y      = element_blank(),
    axis.ticks.y     = element_blank(),
    axis.title.y     = element_blank(),
    axis.line.y      = element_blank(),
    plot.title       = element_text(size=12, face="bold", color="black"),
    plot.subtitle    = element_text(size=9, color="grey40"),
    axis.text.x      = element_text(size=10, color="black"),
    axis.title.x     = element_text(size=11, color="black"),
    plot.margin = margin(10, 20, 10, 180)
  )

ggsave("~/PopSize/results/fst_dendrogram_SH_v2.pdf",
       p, width=9, height=5, device="pdf", bg="white")
ggsave("~/PopSize/results/fst_dendrogram_SH_v2.png",
       p, width=9, height=5, dpi=300, bg="white")

cat("✓ Dendrograma v2 guardado\n")
