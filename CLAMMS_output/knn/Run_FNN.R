# This code requires the FNN (Fast Nearest Neighbors) R package (http://cran.r-project.org/package=FNN)
# To run use Rscript Run_FNN.R "filename" & 
# where "filename" os the name of the file with QC information

args <- commandArgs()
QC_Fil <- args[6] # saves path of QC file in object, i.e. WES_CDH.QC.knn.txt in SAMPLE_INFO_DIR

require(FNN)

# Load the data set into data frame 'example.qcs'
example.qcs <- read.table(paste(QC_Fil), header = TRUE)

# Create a scaled copy of the data frame
example.qcs.scaled <- example.qcs
for (i in 2:ncol(example.qcs.scaled)) {
    mini <- min(example.qcs.scaled[,i])
    maxi <- max(example.qcs.scaled[,i])
    example.qcs.scaled[,i] <- apply(example.qcs.scaled, 1, function(row) { 
                row[[i]] <- (as.numeric(row[[i]]) - mini) / (maxi - mini)
        } )
}

# Get k-nearest neighbors for each sample
k.param <- 50
knns <- get.knn(example.qcs.scaled[,c(seq(2,ncol(example.qcs.scaled)))],k=k.param,algorithm="kd_tree")

# Generate a single file for each sample listing its k-nearest neighbor sample IDs
for (i in 1:nrow(example.qcs.scaled)) {
    fname <- paste(example.qcs.scaled$IID[i], ".", k.param, "nns.txt", sep="")
    nn.sampleids <- example.qcs.scaled$IID[ knns$nn.index[i,] ]
    write.table(nn.sampleids, fname, quote=F, row.names=F, col.names=F)
}
