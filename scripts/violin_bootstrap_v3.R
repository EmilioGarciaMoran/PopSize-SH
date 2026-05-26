library(ggplot2)
library(dplyr)

mu <- 1.25e-8
specimens <- c("femurXIII", "femur_fragment", "molar_L35", "scapula")
labels_sp <- c("FemurXIII", "Femur fragment", "Molar L35", "Scapula")

all_data <- data.frame()
for (i in seq_along(specimens)) {
  sp <- specimens[i]
  lines <- readLines(paste0("~/PopSize/results/bootstrap/", sp, "_boot.sfs"))
  H_vals <- c()
  for (line in lines) {
    v <- suppressWarnings(as.numeric(strsplit(trimws(line), "\\s+")[[1]]))
    if (length(v) == 3 && !any(is.na(v))) {
      H <- v[2] / sum(v)
      H_vals <- c(H_vals, H)
    }
  }
  all_data <- rbind(all_data, data.frame(
    specimen = factor(labels_sp[i], levels = labels_sp),
    H = H_vals
  ))
}

# Referencias — posiciones Y para etiquetas separadas manualmente
refs <- data.frame(
  label     = c("Vindija (this pipeline)",
                "Vindija (Prüfer 2014)",
                "Denisova D17",
                "Ust'-Ishim",
                "H. sapiens AFR"),
  H         = c(0.001277, 0.000700, 0.000500, 0.001000, 0.001300),
  color     = c("#5F5E5A", "#A32D2D", "#854F0B", "#0F6E56", "#534AB7"),
  ltype     = c("dashed", "solid", "dotdash", "dotted", "longdash"),
  label_y   = c(0.001180, 0.000740, 0.000540, 0.001040, 0.001390)  # separadas
)

p <- ggplot(all_data, aes(x = specimen, y = H)) +

  # Líneas de referencia
  geom_hline(yintercept = 0.001277, color = "#5F5E5A", linetype = "dashed",   linewidth = 0.55) +
  geom_hline(yintercept = 0.000700, color = "#A32D2D", linetype = "solid",    linewidth = 0.55) +
  geom_hline(yintercept = 0.000500, color = "#854F0B", linetype = "dotdash",  linewidth = 0.55) +
  geom_hline(yintercept = 0.001000, color = "#0F6E56", linetype = "dotted",   linewidth = 0.55) +
  geom_hline(yintercept = 0.001300, color = "#534AB7", linetype = "longdash", linewidth = 0.55) +

  # Violines
  geom_violin(trim = TRUE, fill = "#85B7EB", color = "#185FA5",
              alpha = 0.70, width = 0.65) +

  # Boxplot
  geom_boxplot(width = 0.09, fill = "white", color = "#0C447C",
               outlier.shape = NA, linewidth = 0.45, coef = 1.5) +

  # Media como punto
  stat_summary(fun = mean, geom = "point", shape = 21,
               size = 2.8, fill = "#042C53", color = "white", stroke = 0.5) +

  # Etiquetas de referencia — posicionadas para no solaparse
  annotate("text", x = 4.48, y = 0.001180, label = "Vindija (this pipeline)",
           hjust = 1, size = 2.7, color = "#5F5E5A", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.000740, label = "Vindija (Prüfer 2014)",
           hjust = 1, size = 2.7, color = "#A32D2D", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.000540, label = "Denisova D17",
           hjust = 1, size = 2.7, color = "#854F0B", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.001040, label = "Ust'-Ishim",
           hjust = 1, size = 2.7, color = "#0F6E56", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.001390, label = "H. sapiens AFR",
           hjust = 1, size = 2.7, color = "#534AB7", fontface = "italic") +

  scale_y_continuous(
    limits = c(0.0003, 0.0027),
    breaks = seq(0.0004, 0.0026, by = 0.0002),
    labels = function(x) sprintf("%.4f", x),
    expand = c(0, 0)
  ) +

  coord_cartesian(clip = "off") +

  labs(
    title = "Genome-wide heterozygosity — Sima de los Huesos (~430 ka)",
    subtitle = "Block bootstrap (n = 100 replicates per specimen)  ·  transversions only  ·  ANGSD v0.941",
    x = NULL,
    y = "Heterozygosity (H)"
  ) +

  theme_classic(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.title    = element_text(size = 12, face = "bold",  color = "black"),
    plot.subtitle = element_text(size =  9, color = "grey40"),
    axis.text.x   = element_text(size = 11, color = "black"),
    axis.text.y   = element_text(size =  9, color = "black"),
    axis.title.y  = element_text(size = 11, color = "black"),
    panel.grid.major.y = element_line(color = "grey92", linewidth = 0.3),
    plot.margin   = margin(10, 110, 10, 10)
  )

ggsave("~/PopSize/results/violin_bootstrap_SH_v3.pdf",
       p, width = 9, height = 6, device = "pdf", bg = "white")
ggsave("~/PopSize/results/violin_bootstrap_SH_v3.png",
       p, width = 9, height = 6, dpi = 300, bg = "white")

cat("✓ v3 guardada\n")

# Tabla resumen final
cat("\n=== TABLA RESUMEN BOOTSTRAP ===\n")
all_data %>%
  group_by(specimen) %>%
  summarise(
    n       = n(),
    H_mean  = round(mean(H), 6),
    H_sd    = round(sd(H), 6),
    IC95_lo = round(quantile(H, 0.025), 6),
    IC95_hi = round(quantile(H, 0.975), 6),
    Ne_uncal = round(H_mean / (4 * mu * (1 - H_mean)), 0),
    Ne_cal   = round(Ne_uncal / 1.82, 0)
  ) %>%
  print()
