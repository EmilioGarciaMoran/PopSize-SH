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

h_vals <- c(femurXIII=0.001183, molar_L35=0.001207,
            scapula=0.000590, femur_fragment=0.000925)

# Clustering jerárquico
dist_obj <- as.dist(fst_mat)
hc <- hclust(dist_obj, method="average")

# Labels con H
hc$labels <- sprintf("%s\n(H=%.4f)", specs, h_vals[specs])

ddata <- dendro_data(hc)

p <- ggplot() +
  geom_segment(data=segment(ddata),
               aes(x=x, y=y, xend=xend, yend=yend),
               linewidth=0.8, color="#185FA5") +
  geom_text(data=label(ddata),
            aes(x=x, y=y, label=label),
            hjust=1, size=3.5, color="black",
            nudge_y=-0.008) +
  geom_point(data=label(ddata),
             aes(x=x, y=0),
             size=4, color="#185FA5") +
  scale_y_continuous(
    name="Fst (distancia genética)",
    limits=c(-0.08, 0.35),
    breaks=seq(0, 0.3, by=0.1)
  ) +
  scale_x_continuous(expand=c(0.2, 0.2)) +
  coord_flip() +
  labs(
    title="Distancia genética entre especímenes de Sima de los Huesos",
    subtitle="Clustering jerárquico (UPGMA) sobre matriz de Fst pairwise · ANGSD v0.940 · transversiones"
  ) +
  theme_classic(base_size=12) +
  theme(
    plot.background=element_rect(fill="white", color=NA),
    axis.text.y=element_blank(),
    axis.ticks.y=element_blank(),
    axis.title.y=element_blank(),
    plot.title=element_text(size=12, face="bold"),
    plot.subtitle=element_text(size=9, color="grey40")
  )

ggsave("~/PopSize/results/fst_dendrogram_SH.png", p,
       width=8, height=5, dpi=300, bg="white")
cat("✓ Dendrograma guardado\n")
