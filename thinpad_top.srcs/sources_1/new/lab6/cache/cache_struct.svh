typedef struct{
    reg [23:0] tag;
    reg valid;
    reg dirty;
    reg [31:0] data; 
} dm_cache_entry;
