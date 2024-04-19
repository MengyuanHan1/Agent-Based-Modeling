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

I1 -->|No| I6{Is the individual's state panic?}

I6 -->|Yes| I7{Are there any affected patches within the vision range?}

I7 -->|Yes| I8[Set the individual to affected state]

I7 -->|No| I9[Set the individual to unaffected state]

I9 --> I10{Has the individual collided with other non-dead individuals?}

I10 -->|Yes| I11[Set the individual's collision state to true]

I10 -->|No| I12[Maintain panic state]

I6 -->|No| I13{Is the individual's state injured?}

I13 -->|Yes| I14{Has the pause time interval been reached?}

I14 -->|Yes| I15{Has the individual reached the safe state?}

I15 -->|Yes| I16[Maintain safe state]

I15 -->|No| I17[Set the individual's state to panic]

I14 -->|No| I18[Maintain injured state]

I13 -->|No| I19[Unexpected state]

H --> J[Individual Behavior Execution Stage]

I5 --> J

I3 --> J

I8 --> J

I11 --> J

I12 --> J

I17 --> J

I18 --> J

I16 --> J

J --> J1{Is the individual's state normal?}

J1 -->|Yes| J2[Individual randomly turns and moves forward]

J1 -->|No| J3{Is the individual's state panic?}

J3 -->|Yes| J4{Is the individual affected by a dead individual?}

J4 -->|Yes| J5[Individual moves in the direction away from the dead individual]

J4 -->|No| J6[Individual moves towards the nearest exit]

J3 -->|No| J7{Is the individual's state injured?}

J7 -->|Yes| J8[Set the individual's speed to 0]

J7 -->|No| K[Update position, check boundary and update speed]

J2 --> K

J5 --> K

J6 --> K

J8 --> K

K --> L[Update affected patches]

L --> M{Is the individual unaffected, not safe, and in a state of panic or injury?}

M -->|Yes| M1{Are there any other non-safe individuals nearby?}

M1 -->|Yes| M2[Set the individual's state to injured]

M2 --> M3{Has the individual reached the boundary?}

M3 -->|Yes| M4[Set the individual's state to safe]

M3 -->|No| N[Draw Current State]

M1 -->|No| N

M -->|No| N

M4 --> N

N --> E
