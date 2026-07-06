struc vbe_info_t
    .signature:        resd 1
    .version:          resw 1
    .oemName:          resd 1
    .capabilities:     resd 1
    .supportedModes:   resd 1
    .vmemBlockCount:   resw 1
    .oemVersion:       resw 1
    .vendorName:       resd 1
    .productName:      resd 1
    .productRevision:  resd 1
    .vbeAFVersion:     resw 1
    .supportedAFModes: resd 1
    .reserved:         resb 216
    .oemReserved:      resb 256
endstruc
