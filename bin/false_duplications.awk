# Code adapted from https://github.com/marbl/merqury/blob/master/eval/false_duplications.sh
$1 == asm_ploidy {
    asm_ploidy_hist[$2] = $3 # Defer processing ploidy copy k-mers until end when cutoff is fixed
    if ( max < $3 ){
        max  = $3
        cutoff = int(sprintf("%.0f",$2 * 1.5))
    }
}
$1 > asm_ploidy && $2 < cutoff {
    $1 == ">4" ? idx = 5 : idx = $1
    cp_sum[idx] += $NF
}
END {
    for (i = 1; i < cutoff; i++){
        cp_sum[asm_ploidy] += asm_ploidy_hist[i]
    }
    for (i = asm_ploidy+1 ; i < 6; i++){
        dup += cp_sum[i]
    }
    OFS="\t"
    print "hist", "cutoff", "1", "2", "3", "4", ">4", "dup(>1)", "all", "dups%"
    print FILENAME, cutoff, cp_sum[1], cp_sum[2], cp_sum[3], cp_sum[4], cp_sum[5], dup, dup+cp_sum[asm_ploidy], (100*dup)/(dup+cp_sum[asm_ploidy])
}
