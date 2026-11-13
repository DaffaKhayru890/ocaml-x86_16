; Titik masuk menerima kendali dari far jump pada vektor reset.
firmware_entry:
    cli
    cld
    jmp initialize_segments
