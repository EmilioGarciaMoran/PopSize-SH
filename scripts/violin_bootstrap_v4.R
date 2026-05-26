library(ggplot2)
library(dplyr)

mu <- 1.25e-8
inflation <- 1.82
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
      H_raw <- v[2] / sum(v)
      H_cal <- H_raw / inflation  # calibrado
      H_vals <- c(H_vals, H_cal)
    }
  }
  all_data <- rbind(all_data, data.frame(
    specimen = factor(labels_sp[i], levels = labels_sp),
    H = H_vals
  ))
}

# Referencias publicadas (ya calibradas)
# Vindija pipeline también calibrado: 0.001277 / 1.82 = 0.000701
p <- ggplot(all_data, aes(x = specimen, y = H)) +

  geom_hline(yintercept = 0.001277/inflation, color = "#5F5E5A", linetype = "dashed",   linewidth = 0.55) +
  geom_hline(yintercept = 0.000700,           color = "#A32D2D", linetype = "solid",    linewidth = 0.55) +
  geom_hline(yintercept = 0.000500,           color = "#854F0B", linetype = "dotdash",  linewidth = 0.55) +
  geom_hline(yintercept = 0.001000,           color = "#0F6E56", linetype = "dotted",   linewidth = 0.55) +
  geom_hline(yintercept = 0.001300,           color = "#534AB7", linetype = "longdash", linewidth = 0.55) +

  geom_violin(trim = TRUE, fill = "#85B7EB", color = "#185FA5",
              alpha = 0.70, width = 0.65) +
  geom_boxplot(width = 0.09, fill = "white", color = "#0C447C",
               outlier.shape = NA, linewidth = 0.45) +
  stat_summary(fun = mean, geom = "point", shape = 21,
               size = 2.8, fill = "#042C53", color = "white", stroke = 0.5) +

  annotate("text", x = 4.48, y = 0.001277/inflation - 0.000040,
           label = "Vindija (this pipeline, calibrated)",
           hjust = 1, size = 2.7, color = "#5F5E5A", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.000700 + 0.000040,
           label = "Vindija (Prufer 2014)",
           hjust = 1, size = 2.7, color = "#A32D2D", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.000500 - 0.000040,
           label = "Denisova D17",
           hjust = 1, size = 2.7, color = "#854F0B", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.001000 + 0.000040,
           label = "Ust'-Ishim",
           hjust = 1, size = 2.7, color = "#0F6E56", fontface = "italic") +
  annotate("text", x = 4.48, y = 0.001300 + 0.000040,
           label = "H. sapiens AFR",
           hjust = 1, size = 2.7, color = "#534AB7", fontface = "italic") +

  scale_y_continuous(
    limits = c(0.0002, 0.0016),
    breaks = seq(0.0002, 0.0016, by = 0.0002),
    labels = function(x) sprintf("%.4f", x),
    expand = c(0, 0)
  ) +

  coord_cartesian(clip = "off") +

  labs(
    title = "Genome-wide heterozygosity - Sima de los Huesos (~430 ka)",
    subtitle = "Calibrated values (pipeline inflation factor 1.82x)  .  Block bootstrap (n = 100)  .  transversions only  .  ANGSD v0.941",
    x = NULL,
    y = "Heterozygosity (H, calibrated)"
  ) +

  theme_classic(base_size = 12) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.title    = element_text(size = 12, face = "bold", color = "black"),
    plot.subtitle = element_text(size =  9, color = "grey40"),
    axis.text.x   = element_text(size = 11, color = "black"),
    axis.text.y   = element_text(size =  9, color = "black"),
    axis.title.y  = element_text(size = 11, color = "black"),
    panel.grid.major.y = element_line(color = "grey92", linewidth = 0.3),
    plot.margin   = margin(10, 130, 10, 10)
  )

ggsave("~/PopSize/results/violin_bootstrap_SH_v4.pdf",
       p, width = 9, height = 6, device = "pdf", bg = "white")
ggsave("~/PopSize/results/violin_bootstrap_SH_v4.png",
       p, width = 9, height = 6, dpi = 300, bg = "white")

cat("Calibrated summary:\n")
all_data %>%
  group_by(specimen) %>%
  summarise(
    H_mean  = round(mean(H), 6),
    IC95_lo = round(quantile(H, 0.025), 6),
    IC95_hi = round(quantile(H, 0.975), 6),
    Ne_cal  = round(mean(H) / (4 * mu * (1 - mean(H))), 0)
  ) %>% print()

cat("\nRatio SH/Vindija (Prufer): ", round(mean(all_data$H) / 0.000700, 2), "x\n")
cat("Ratio SH/Vindija (pipeline calibrated): ",
    round(mean(all_data$H) / (0.001277/inflation), 2), "x\n")
