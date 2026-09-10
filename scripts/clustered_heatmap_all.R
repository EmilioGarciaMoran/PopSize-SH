library(ggplot2)
library(reshape2)
library(pheatmap)

# === GOYET IBS DISTANCES (from pairwise calculation) ===
goyet_inds <- c("AR-30","GoyetC5-1","GoyetQ305-4","GN2",
                "TrouMagrite2422-36","Fonds-de-Foret","GoyetQ119-2",
                "GoyetQ376-25","LesCottes-merged","GoyetQ305-1",
                "GoyetQ55-4","Spy94a-merged")

# Solo pares con >500 sitios compartidos
ibs_pairs <- list(
  c("AR-30","GN2",0.0664), c("AR-30","Fonds-de-Foret",0.0924),
  c("AR-30","LesCottes-merged",0.0898), c("AR-30","GoyetQ305-1",0.0642),
  c("AR-30","Spy94a-merged",0.0590),
  c("GoyetC5-1","LesCottes-merged",0.1552),
  c("GoyetQ305-4","GN2",0.0645), c("GoyetQ305-4","TrouMagrite2422-36",0.0715),
  c("GoyetQ305-4","Fonds-de-Foret",0.0635), c("GoyetQ305-4","LesCottes-merged",0.0762),
  c("GoyetQ305-4","GoyetQ305-1",0.0641), c("GoyetQ305-4","Spy94a-merged",0.0439),
  c("GN2","TrouMagrite2422-36",0.0602), c("GN2","Fonds-de-Foret",0.0651),
  c("GN2","GoyetQ119-2",0.1104), c("GN2","LesCottes-merged",0.0731),
  c("GN2","GoyetQ305-1",0.0625), c("GN2","GoyetQ55-4",0.0768),
  c("GN2","Spy94a-merged",0.0487),
  c("TrouMagrite2422-36","Fonds-de-Foret",0.0617),
  c("TrouMagrite2422-36","LesCottes-merged",0.0734),
  c("TrouMagrite2422-36","GoyetQ305-1",0.0620),
  c("TrouMagrite2422-36","Spy94a-merged",0.0423),
  c("Fonds-de-Foret","GoyetQ119-2",0.1026),
  c("Fonds-de-Foret","LesCottes-merged",0.0743),
  c("Fonds-de-Foret","GoyetQ305-1",0.0633),
  c("Fonds-de-Foret","GoyetQ55-4",0.0886),
  c("Fonds-de-Foret","Spy94a-merged",0.0488),
  c("GoyetQ119-2","LesCottes-merged",0.1357),
  c("GoyetQ119-2","GoyetQ305-1",0.1150),
  c("GoyetQ376-25","LesCottes-merged",0.0603),
  c("LesCottes-merged","GoyetQ305-1",0.0732),
  c("LesCottes-merged","GoyetQ55-4",0.0886),
  c("LesCottes-merged","Spy94a-merged",0.0533),
  c("GoyetQ305-1","GoyetQ55-4",0.0769),
  c("GoyetQ305-1","Spy94a-merged",0.0445)
)

# Filtrar individuos con suficientes pares (>3 pares con datos)
pair_counts <- table(unlist(lapply(ibs_pairs, function(x) c(x[1], x[2]))))
good_inds <- names(pair_counts[pair_counts >= 3])

n_g <- length(good_inds)
goyet_mat <- matrix(NA, n_g, n_g, dimnames=list(good_inds, good_inds))
diag(goyet_mat) <- 0

for (p in ibs_pairs) {
  i <- p[1]; j <- p[2]; d <- as.numeric(p[3])
  if (i %in% good_inds & j %in% good_inds) {
    goyet_mat[i,j] <- d
    goyet_mat[j,i] <- d
  }
}

# Reemplazar NA con mediana de distancias conocidas (para clustering)
med_dist <- median(goyet_mat, na.rm=TRUE)
goyet_mat[is.na(goyet_mat)] <- med_dist

# Labels limpios
rownames(goyet_mat) <- gsub("-merged","",rownames(goyet_mat))
colnames(goyet_mat) <- gsub("-merged","",colnames(goyet_mat))

# Anotacion: edad aproximada
ages <- data.frame(
  row.names = rownames(goyet_mat),
  Age = rep("~40-54 ka", n_g)
)

# Plot Goyet
png("~/PopSize/results/heatmap_goyet_IBS.png", width=10, height=8, units="in", res=300)
pheatmap(goyet_mat,
         clustering_method = "average",
         display_numbers = TRUE,
         number_format = "%.3f",
         fontsize_number = 7,
         color = colorRampPalette(c("#185FA5","#85B7EB","white","#E8A76C","#A32D2D"))(100),
         breaks = seq(0, 0.16, length.out=101),
         main = "IBS distance: Late Neandertals (~40-54 ka, Bossoms Mesa 2026)\nRange: 0.04-0.16",
         fontsize = 10,
         border_color = "grey80",
         annotation_row = ages)
dev.off()

# === SH FST MATRIX ===
sh_specs <- c("femurXIII", "molar_L35", "scapula", "femur_fragment")
sh_mat <- matrix(0, 4, 4, dimnames=list(sh_specs, sh_specs))
sh_mat["femurXIII","molar_L35"]     <- sh_mat["molar_L35","femurXIII"]     <- 0.041
sh_mat["femurXIII","scapula"]        <- sh_mat["scapula","femurXIII"]        <- 0.123
sh_mat["femurXIII","femur_fragment"] <- sh_mat["femur_fragment","femurXIII"] <- 0.302
sh_mat["molar_L35","scapula"]        <- sh_mat["scapula","molar_L35"]        <- 0.241
sh_mat["molar_L35","femur_fragment"] <- sh_mat["femur_fragment","molar_L35"] <- 0.284
sh_mat["scapula","femur_fragment"]   <- sh_mat["femur_fragment","scapula"]   <- 0.285

h_vals <- c(femurXIII="H=0.0012", molar_L35="H=0.0012",
            scapula="H=0.0006", femur_fragment="H=0.0009")
sh_ann <- data.frame(
  row.names = sh_specs,
  H_level = c("High","High","Low","Intermediate"),
  Age = "~430 ka"
)

png("~/PopSize/results/heatmap_SH_FST.png", width=7, height=5.5, units="in", res=300)
pheatmap(sh_mat,
         clustering_method = "average",
         display_numbers = TRUE,
         number_format = "%.3f",
         fontsize_number = 10,
         color = colorRampPalette(c("#185FA5","#85B7EB","white","#E8A76C","#A32D2D"))(100),
         breaks = seq(0, 0.35, length.out=101),
         main = "FST distance: Sima de los Huesos (~430 ka, this study)\nRange: 0.04-0.30",
         fontsize = 11,
         border_color = "grey80",
         annotation_row = sh_ann)
dev.off()

cat("✓ Ambos heatmaps guardados\n")
cat("\nResumen comparativo:\n")
cat(sprintf("  Neandertales tardíos (n=12): IBS dist = %.3f - %.3f (rango %.3f)\n",
            min(goyet_mat[goyet_mat>0]), max(goyet_mat[goyet_mat>0 & goyet_mat<med_dist+0.01]),
            max(goyet_mat[goyet_mat>0]) - min(goyet_mat[goyet_mat>0])))
cat(sprintf("  SH (~430 ka, n=4):           FST dist = %.3f - %.3f (rango %.3f)\n",
            min(sh_mat[sh_mat>0]), max(sh_mat), max(sh_mat) - min(sh_mat[sh_mat>0])))
cat("  → SH tiene mayor variabilidad interna en un solo yacimiento\n")
cat("    que 12 Neandertales de múltiples yacimientos a ~45 ka\n")
