suppressMessages(library(Seurat))
suppressMessages(library(Matrix))
suppressMessages(library(rhdf5))

filename<-readLines("inputrdsfile.txt")
A<-readRDS(filename)

# counts_matrix = GetAssayData(seurat_obj, slot="counts")
# see: https://github.com/broadinstitute/inferCNV/wiki/infercnv-10x

gname<-rownames(A@assays$RNA)
if (is.null(gname)){
    gname<-rownames(A@assays$RNA@counts)
}
write.csv(gname,file='g.csv')


tryCatch(
{
    X=A@assays$RNA@counts
    X<-as.matrix(X)
    h5write(X, "output.h5", "X")
},
error = function(msg){
	# write.csv(A@assays$RNA@counts, file = 'X.csv', col.names=F)  #
	write.table(A@assays$RNA@counts, file = 'X.csv', sep=",", col.names=FALSE, row.names=FALSE)
	}
)


# bcode<-colnames(A@assays$RNA@counts)

tryCatch(
    {
         write.csv(rownames(A@meta.data), file='barcodes.csv')
    },
    error = function(e){ 
        # (Optional)
        # Do this if an error is caught...
    }
)

tryCatch(
    {
         write.csv(A@reductions$umap@cell.embeddings, file = 'umap.csv')
    },
    error = function(e){ 
        # (Optional)
        # Do this if an error is caught...
    }
)


tryCatch(
    {
         write.csv(A@meta.data$annotation, file = 'annotation.csv')
    },
    error = function(e){ 
        # (Optional)
        # Do this if an error is caught...
    }
)

