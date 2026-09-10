library(ggplot2)

specs <- c("femurXIII", "molar_L35", "scapula", "femur_fragment")

fst_mat <- matrix(NA, 4, 4, dimnames=list(specs, specs))
fst_mat["femurXIII","molar_L35"]      <- 0.041
fst_mat["femurXIII","scapula"]         <- 0.123
fst_mat["femurXIII","femur_fragment"]  <- 0.302
fst_mat["molar_L35","scapula"]         <- 0.241
fst_mat["molar_L35","femur_fragment"]  <- 0.284
fst_mat["scapula","femur_fragment"]    <- 0.285
# simetrica
for(i in 1:4) for(j in 1:4) if(is.na(fst_mat[i,j])) fst_mat[i,j] <- fst_mat[j,i]
diag(fst_mat) <- 0

df <- reshape2::melt(fst_mat)
df$Var1 <- factor(df$Var1, levels=specs)
df$Var2 <- factor(df$Var2, levels=rev(specs))

# Añadir H para anotación
h_vals <- c(femurXIII=0.001183, molar_L35=0.001207,
            scapula=0.000590, femur_fragment=0.000925)

p <- ggplot(df, aes(x=Var1, y=Var2, fill=value)) +
  geom_tile(color="white", linewidth=0.5) +
  geom_text(aes(label=ifelse(is.na(value)|value==0, "",
                             sprintf("%.3f", value))),
            size=4, color="white", fontface="bold") +
  scale_fill_gradientn(
    colors=c("#185FA5","#85B7EB","#F5F0E8","#E87B3A","#A32D2D"),
    values=c(0,0.1,0.3,0.6,1),
    limits=c(0,0.35),
    name="Fst",
    na.value="grey90"
  ) +
  labs(
    title="Pairwise Fst between Sima de los Huesos specimens",
    subtitle=sprintf("H calibrada: femurXIII=%.4f  molar_L35=%.4f  scapula=%.4f  femur_frag=%.4f",
                     h_vals["femurXIII"], h_vals["molar_L35"],
                     h_vals["scapula"], h_vals["femur_fragment"]),
    x=NULL, y=NULL
  ) +
  theme_minimal(base_size=12) +
  theme(
    plot.background=element_rect(fill="white",color=NA),
    axis.text=element_text(size=11,color="black"),
    plot.title=element_text(size=12,face="bold"),
    plot.subtitle=element_text(size=9,color="grey40"),
    legend.position="right"
  )

ggsave("~/PopSize/results/fst_heatmap_SH.png", p,
       width=7, height=6, dpi=300, bg="white")
cat("✓ Heatmap guardado\n")
