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

h_vals  <- c(femurXIII=0.001183, molar_L35=0.001207, scapula=0.000590, femur_fragment=0.000925)
ne_vals <- round(h_vals/1.82 / (4*1.25e-8*(1-h_vals/1.82)))

hc     <- hclust(as.dist(fst_mat), method="average")
ddata  <- dendro_data(hc)
lab_df <- label(ddata)
seg_df <- segment(ddata)

col_map <- c(femurXIII="#185FA5", molar_L35="#185FA5",
             scapula="#0F6E56", femur_fragment="#854F0B")
lab_df$color    <- col_map[lab_df$label]
lab_df$ne_label <- sprintf("%s\nH=%.4f · Ne~%s",
                           lab_df$label,
                           h_vals[lab_df$label],
                           format(ne_vals[lab_df$label], big.mark=","))

p <- ggplot() +
  # Fondos de cluster
  annotate("rect", xmin=0.5, xmax=2.5, ymin=-0.06, ymax=0.31,
           fill="#E6F1FB", alpha=0.4) +
  annotate("rect", xmin=2.5, xmax=3.5, ymin=-0.06, ymax=0.31,
           fill="#E6F5F0", alpha=0.4) +
  annotate("rect", xmin=3.5, xmax=4.5, ymin=-0.06, ymax=0.31,
           fill="#F5EDE6", alpha=0.4) +

  # Dendrograma vertical
  geom_segment(data=seg_df,
               aes(x=x, y=y, xend=xend, yend=yend),
               linewidth=0.9, color="grey30") +

  # Puntos en hojas
  geom_point(data=lab_df, aes(x=x, y=0, color=color),
             size=5, show.legend=FALSE) +
  scale_color_identity() +

  # Labels debajo de los puntos
  geom_text(data=lab_df,
            aes(x=x, y=-0.025, label=ne_label, color=color),
            size=3.2, show.legend=FALSE,
            lineheight=0.85, fontface="bold") +

  # Anotaciones de cluster arriba
  annotate("text", x=1.5, y=0.29,
           label="Cluster A\n(MIS 11 - interglacial)",
           size=2.8, color="#185FA5", fontface="italic", lineheight=0.85) +
  annotate("text", x=3.0, y=0.29,
           label="Cluster B\n(MIS 12 - glacial)",
           size=2.8, color="#0F6E56", fontface="italic", lineheight=0.85) +
  annotate("text", x=4.0, y=0.29,
           label="Outlier\n(origen distinto?)",
           size=2.8, color="#854F0B", fontface="italic", lineheight=0.85) +

  scale_y_continuous(
    name   = expression(F[ST]~"(genetic distance)"),
    limits = c(-0.07, 0.33),
    breaks = c(0, 0.1, 0.2, 0.3),
    expand = c(0, 0)
  ) +
  scale_x_continuous(expand=c(0.15, 0.15)) +

  labs(
    title    = "Genetic structure among Sima de los Huesos specimens (~430 ka)",
    subtitle = "UPGMA clustering  \u00b7  pairwise FST  \u00b7  ANGSD v0.940  \u00b7  transversions only  \u00b7  calibrated H (1.82\u00d7)"
  ) +

  theme_classic(base_size=12) +
  theme(
    plot.background  = element_rect(fill="white", color=NA),
    panel.background = element_rect(fill="white", color=NA),
    axis.text.x      = element_blank(),
    axis.ticks.x     = element_blank(),
    axis.title.x     = element_blank(),
    axis.line.x      = element_blank(),
    plot.title       = element_text(size=12, face="bold"),
    plot.subtitle    = element_text(size=9, color="grey40"),
    plot.margin      = margin(10, 20, 80, 20)
  )

ggsave("~/PopSize/results/fst_dendrogram_SH_v3.png",
       p, width=9, height=7, dpi=300, bg="white")
cat("✓ v3 guardado\n")
