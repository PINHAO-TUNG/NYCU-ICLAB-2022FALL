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

Pad: I_CLK            N
Pad: I_RESET          N
Pad: I_VALID          N

Pad: I_SOURCE_0       S
Pad: I_SOURCE_1       S
Pad: I_SOURCE_2       S
Pad: I_SOURCE_3       S

Pad: I_DESTINATION_0  W
Pad: I_DESTINATION_1  W
Pad: I_DESTINATION_2  W
Pad: I_DESTINATION_3  W

Pad: O_VALID          N
Pad: O_COST_0         E
Pad: O_COST_1         E
Pad: O_COST_2         E
Pad: O_COST_3         E

#IO power
Pad: VDDP0        N
Pad: GNDP0        N
Pad: VDDP1        W
Pad: GNDP1        W
Pad: VDDP2        E
Pad: GNDP2        E
Pad: VDDP3        S
Pad: GNDP3        S
Pad: VDDP4        N
Pad: GNDP4        N
Pad: VDDP5        W
Pad: GNDP5        W
Pad: VDDP6        E
Pad: GNDP6        E
Pad: VDDP7        S
Pad: GNDP7        S

#Core poweri
Pad: VDDC0        N
Pad: GNDC0        N
Pad: VDDC1        W
Pad: GNDC1        W
Pad: VDDC2        E
Pad: GNDC2        E
Pad: VDDC3        S
Pad: GNDC3        S
Pad: VDDC4        N
Pad: GNDC4        N
Pad: VDDC5        W
Pad: GNDC5        W
Pad: VDDC6        E
Pad: GNDC6        E
Pad: VDDC7        S
Pad: GNDC7        S

# corner
Pad: PCLR SE PCORNER
Pad: PCUL NW PCORNER
Pad: PCUR NE PCORNER
Pad: PCLL SW PCORNER
