# Agent-Based-Modeling

## Model Logic
***Check if you like***

```mermaid
graph TD
A[Start] --> B[Initialize Environment]
B --> C[Create Individuals]
C --> D[Draw Initial State]
D --> E{Have all individuals reached safe or dead state?}
E -->|Yes| Z[End]
E -->|No| F{Has the event trigger time been reached?}
F -->|Yes| G[Randomly select a non-dead individual and set its state to dead]
G --> H[Set other individuals within the affected range of the dead individual to panic state]
F -->|No| I[Individual State Decision Stage]
I --> I1{Is the individual's state normal?}
I1 -->|Yes| I2{Are there any affected patches within the vision range?}
I2 -->|Yes| I3[Set the individual's state to panic]
I2 -->|No| I4{Are there any individuals in panic state within the vision range?}
I4 -->|Yes| I3
I4 -->|No| I5[Maintain normal state]
I1 -->|No| I6{Has the individual reached the safe state?}
I6 -->|Yes| I16[Maintain safe state]
I6 -->|No| I7{Is the individual's state panic?}
I7 -->|Yes| I8{Are there any affected patches within the vision range?}
I8 -->|Yes| I9[Set the individual to affected state]
I8 -->|No| I10[Set the individual to unaffected state]
I10 --> I11{Has the individual collided with other non-dead individuals?}
I11 -->|Yes| I12[Set the individual's collision state to true]
I7 -->|No| I13{Is the individual's state injured?}
I13 -->|Yes| I14{Has the pause time interval been reached and the individual has not reached the safe state?}
I14 -->|Yes| I15[Set the individual's state to panic]
I14 -->|No| I16[Maintain injured state]
H --> J[Individual Behavior Execution Stage]
I5 --> J
I3 --> J
I9 --> J
I12 --> J
I11 -->|No| J
I15 --> J
I16 --> J
I13 -->|No| J
J --> J1{Is the individual's state normal?}
J1 -->|Yes| J2[Individual randomly turns and moves forward]
J1 -->|No| J3{Is the individual's state panic?}
J3 -->|Yes| J5{Is the individual affected by a dead individual?}
J5 -->|Yes| J6[Individual moves in the direction away from the dead individual]
J5 -->|No| J7[Individual moves towards the nearest exit]
J3 -->|No| J8{Is the individual's state injured?}
J8 -->|Yes| J9[Set the individual's speed to 0]
J8 -->|No| J10[Update the individual's position and adjust speed]
J2 --> K[Check if the individual has crossed the boundary and update its state]
J6 --> K
J7 --> K
J9 --> K
J10 --> K
K --> L{Is the individual unaffected and in a state of panic or injury?}
L -->|Yes| L1{Are there any other individuals in non-safe states nearby?}
L1 -->|Yes| L2[Set the individual's state to injured]
L2 --> L3{Has the individual reached the boundary?}
L3 -->|Yes| L4[Set the individual's state to safe]
L3 -->|No| M[Update affected patches]
L1 -->|No| M
L -->|No| M
L4 --> M
M --> N[Draw Current State]
N --> E
