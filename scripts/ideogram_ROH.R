library(ggplot2)
library(dplyr)

specimens <- c("femurXIII", "femur_fragment", "molar_L35", "scapula")
labels_sp <- c("FemurXIII", "Femur fragment", "Molar L35", "Scapula")

autosomes <- paste0("chr", 1:22)

all_data <- data.frame()
for (i in seq_along(specimens)) {
  sp <- specimens[i]
  df <- read.table(
    gzfile(paste0("~/PopSize/results/roh/", sp, ".mid.hmmp.gz")),
    header = TRUE, sep = "\t", comment.char = "#",
    col.names = c("chrom", "begin", "end", "p_roh", "p_nonroh")
  )
  df <- df[df$chrom %in% autosomes, ]
  df$specimen <- labels_sp[i]
  df$chr_num <- as.integer(sub("chr", "", df$chrom))
  df$mid <- (df$begin + df$end) / 2e6  # en Mb
  all_data <- rbind(all_data, df)
}

all_data$specimen <- factor(all_data$specimen, levels = rev(labels_sp))
all_data$chrom <- factor(all_data$chrom, levels = autosomes)

p <- ggplot(all_data, aes(x = mid, y = specimen, fill = p_roh)) +
  geom_tile(width = 3, height = 0.85) +
  facet_wrap(~ chrom, nrow = 4, scales = "free_x") +
  scale_fill_gradientn(
    colors = c("white", "#B5D4F4", "#378ADD", "#0C447C", "#042C53"),
    values = c(0, 0.05, 0.15, 0.35, 1),
    limits = c(0, 1),
    name = "p(ROH)",
    breaks = c(0, 0.25, 0.5, 0.75, 1),
    labels = c("0", "0.25", "0.50", "0.75", "1.0")
  ) +
  labs(
    title = "ROH probability across autosomes - Sima de los Huesos (~430 ka)",
    subtitle = "ROHan HMM p(ROH) per 3 Mb window . mid estimate",
    x = "Position (Mb)",
    y = NULL
  ) +
  theme_minimal(base_size = 9) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "grey97", color = NA),
    strip.text = element_text(size = 8, face = "bold"),
    axis.text.x = element_text(size = 6),
    axis.text.y = element_text(size = 8),
    legend.position = "right",
    panel.grid = element_blank(),
    plot.title = element_text(size = 11, face = "bold"),
    plot.subtitle = element_text(size = 8, color = "grey40"),
    panel.spacing = unit(0.3, "lines")
  )

ggsave("~/PopSize/results/ideogram_ROH_SH.pdf",
       p, width = 16, height = 10, device = "pdf", bg = "white")
ggsave("~/PopSize/results/ideogram_ROH_SH.png",
       p, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Ideograma guardado\n")
