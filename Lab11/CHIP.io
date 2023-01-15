######################################################
#                                                    #
#  Silicon Perspective, A Cadence Company            #
#  FirstEncounter IO Assignment                      #
#                                                    #
######################################################

Version: 2

#Example:  
#Pad: I_CLK 		W

#define your iopad location here

Pad: I_CLK        N
Pad: I_RESET      N
Pad: I_VALID      N
Pad: I_VALID_2    S
Pad: I_SIZE_0     S
Pad: I_SIZE_1     S
Pad:
Pad: I_W_MAT_IDX  W
Pad: I_I_MAT_IDX  W
Pad: I_MATRIX     W
Pad: O_VALID      E
Pad: O_VALUE      E
Pad:
Pad:
Pad: VDDP0        N
Pad: GNDP0        N
Pad: VDDP1        W
Pad: GNDP1        W
Pad: VDDP2        E
Pad: GNDP2        E
Pad: VDDP3        S
Pad: GNDP3        S

Pad: VDDC0        N
Pad: GNDC0        N
Pad: VDDC1        W
Pad: GNDC1        W
Pad: VDDC2        E
Pad: GNDC2        E
Pad: VDDC3        S
Pad: GNDC3        S

# corner
Pad: PCLR SE PCORNER
Pad: PCUL NW PCORNER
Pad: PCUR NE PCORNER
Pad: PCLL SW PCORNER