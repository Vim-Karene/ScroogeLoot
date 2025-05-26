# ScroogeLoot
                                                                                                                
                                                                                                                
                                                                                                                
                                       @@@@@@@@@@@@@@@                                                          
                                @@@@@@@@@@@@@@@@@@@@@@                                                          
                           @@@@@@@@@@@@@@@@@@@@@@@@@@@                                                          
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         
                      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         
                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         
                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                         
                         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                        
                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                        
                           @@@@@@@@@@@@@@@@@@@@@      @@                                                        
                            @@@@@@@@@@@@               @@     @@@@@@                                            
                            @@@@@@                     @@@@@@@@@@@@                                             
                             @@                   @@@@@@@@@@@@@@@                                               
                              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                                   
                           @@@@@@@@@@@@@@@@@@@@@@@@@@      @@                                                   
                        @@@@@@@@@@@@      @@@@@@          @@@@@                                                 
                       @@@@@@@@@       @@       @@      @    @@@                                                
                      @@@@@@@@@                                @@                                               
                            @@                     @@           @@                                              
                           @@                       @@          @@                                              
                           @@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                              
                    @@     @@         @    @@@@     @@  @@@@     @                                              
                   @@      @@         @@            @@@@@@      @@        @@@@@@                                
                  @@       @@          @@         @@@    @@@@  @@    @@@@@     @@                               
                  @@@      @@         @@@@@@@@@@@@@         @@@@@@@@@         @@                                
                    @@      @@      @@@@@                                   @@@                                 
                     @@      @@   @@@@@@@@@                             @@@@@                                   
                     @       @@@@@@@@@@@@@@@@@                  @@@@@@@@@         @@@@                          
                         @@@@@@@@@@@@@@@@@    @@@@@@@@@@@@@@@@@@     @@     @@@@@@@  @@@@@@@@                   
                     @@@@@   @@@@@@@@@@@@@                       @@@@@     @@               @@                  
                    @@@ @@@   @@@@@@@@    @@@@@@@@@@@@@@@@@@@@@@@           @@             @@                   
                    @@@@ @@@@@@      @@         @@@ @                        @@      @   @@@                    
                     @@@@@@           @@        @@                          @@@@@@  @@@ @@                      
                                      @@        @@                        @@@    @@@@@@@@@@@                    
                                       @        @@@                      @@       @@@      @@                   
                                      @@         @@@                    @@   @     @@@@@@@@@                    
                                    @@@            @@                   @@   @@   @@       @@                   
                                 @@@                 @@@                @   @@@@@@@@      @@                    
                              @@@                      @@@             @@@@@@      @@@@@@@@@                    
                            @@@                          @@@@      @@@@@@@@                 @@@                 
                         @@@                               @@@@@@@@   @@@         @@  @       @@@               
                        @@                                  @@@     @@@           @@ @@@        @@              
                      @@@                                     @@   @@@          @@@@@@@@@@       @@@            
                     @@@              @@                       @@ @@          @@@ @@  @@          @@@           
                    @@               @@                         @@@           @@@ @@   @           @@@          
                   @@               @@                          @@@             @@@@@@@@@           @@          
                  @@               @@@                           @                @@  @@@@@@        @@          
                 @@                @@                           @@                @@   @  @@         @          
                 @@               @@                             @            @@@ @@   @  @@        @@          
                @@                @@                             @@             @@@@@@@@@@          @@          
                @@                @@                              @@              @@   @           @@           
               @@                @@                               @@@                            @@@            
               @@                @@                               @@@@@@                       @@@              
               @@                @@                               @@   @@@@@@            @@@@@@                 
                                                                             @@@@@@@@@@@@@                      
                                                                                                                
                                                                                                                

Scrooge Loot is a customized version of RCLootCouncil, tailored to support a unique loot and attendance system originally developed for the *Dancing Boars* raid guild on the Turtle WoW private server, but will now support *Disco Ducks* in Epoch WoW. What started as a quirky but powerful tool to handle loot, duck points, and token rolls has grown into a full-fledged, officially supported addon for Epoch WoW private server.

## ✨ What Is Scrooge Loot?
Scrooge Loot is a raid loot management addon built on top of the trusted RCLootCouncil framework for World of Warcraft 3.3.5a, modified to support custom point-based loot distribution systems and enhanced raid tracking.

It is designed exclusively for raid leaders and loot masters who want advanced control, transparency, and automation when it comes to distributing loot and managing attendance.

## 🧠 Key Features

- Duck Points (DP) & Token Points (TP) system
- Full loot council integration with adjustable point modifiers
- Automatic attendance tracking, including handling absentees
- Export/import of player variable sheets via XML
- Class-colored UI for easier player identification
- Loot transparency and real-time syncing across the raid
- Manual editing of player points and tokens in-game
- UI dropdown for loot masters to manage systems easily

## 📜 Origins
Scrooge Loot began as a custom mod for the semi-serious, semi-chaotic raid group Dancing Boars on Turtle WoW. It was created to handle our strange mix of duck-themed point rolls, token limitations, and quirky player rules. The system worked so well it caught on—leading to its adoption and refinement for broader use.

It’s now the official loot addon for Epoch WoW, where it continues to evolve to fit the needs of our raiding community.

## 🧩 Requirements
- World of Warcraft 3.3.5a client (Epoch WoW compatible)
- All raiders need to install it for it to work properly.

## 📁 Installation

1. Download the latest Scrooge Loot ZIP.
2. Unzip the folder into your Interface/AddOns/ directory.
3. Make sure the folder is named ScroogeLoot (not double-nested).
4. Enable it on the character selection screen.

# 🦆 Scrooge Loot – How the System is intended to work:

## 🪙 TOKEN ROLL *(Highest Priority)*
- **Only available to raiders**.
- Each raider selects **3 token items** from the current raid tier.
- You start with **0 Token Points (TP)**.
- If a token item drops:
  - If **only you** tokened it → you get it automatically.
  - If **multiple players** tokened it → you **roll**, and your TP is **added** to your roll.
- **Winning** the roll:
  - Your **TP resets to 0**
  - You **consume that token slot** for the raid tier.
- **Losing** the roll:
  - You gain **+20 TP**.
- For every full **raid reset attended**, you earn **+10 TP**.
- You may change one of your chosen token items up to **3 times** per tier.

---

## 🟪 DUCK ROLL *(Second Priority)*
- Only available to **raiders**.
- Used for items not covered by Token Rolls.
- If you win a Duck Roll:
  - You gain **-50 Duck Points (DP)** (this is a **roll penalty**).
- Every raid you attend restores **+25 DP** (up to a max of 0).
- Your current DP is **subtracted** from future rolls.
- Duck Points are **separate** from Token Points.

---

## 🟩 MAIN SPEC (MS) ROLL *(Third Priority)*
- **Open to everyone**, raider or non-raider.
- Used for items that are an upgrade to your **main spec**.
- If you're a raider and have negative duck points, your **DP penalty applies here**.

---

## 🟧 OFF SPEC (OS) ROLL *(Fourth Priority)*
- **Open to everyone**.
- Used for gear not suited for your current spec but still useful.
- raiders with negative DP are **penalized here too**.

---

## ⚪ TRANSMOG ROLL *(Lowest Priority)*
- **Open to everyone**, no restrictions.
- Used for **cosmetic** or **vanity** items only.
- No points are gained or lost.
- Has the **lowest loot priority**.

---


## ⚖️ License & Credits
Scrooge Loot is a fork of RCLootCouncil, and retains its original license:
GNU General Public License v3.0 (GPLv3).

All original credits go to the authors of RCLootCouncil.
This addon is provided as-is and remains open-source for community use and improvement.

