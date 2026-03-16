# Demo Production Plan

---

## Week 1 　3/12–3/18　Gameplay Loop

**目標：讓 demo 核心循環能跑通——生怪、打怪、掉 soul、召喚**

### 已完成

- [x]  Arena map（1600×1600 手刻）
- [x]  Soul pickup 系統（soul loot + pickup；stats 有位但 demo 無視 mana bar）
- [x]  Enemy simple refactor
- [x]  Audio refactor
- [x]  Generic spawn system
- [x]  **Objective 系統**　擊殺計數 → 達標解鎖下一批 spawn table，直到解鎖龍 boss 戰
- [x]  **Encounter manager**　管理整套生怪邏輯；spawn table 切換（wave → wave → boss）
- [x]  **Player setup（Demo 專用）**　Able to 鎖最低 HP 為 1 (undead mode) and god mode (Attack range to very far, oneshot kill, no damage taken), add loot collector and other missing systems or module

### 本週任務

- [ ]  **Basic UI — 召喚槽 + Soul 顯示**　初始狀態全 disabled；根據 soul 值動態開關召喚槽
- [ ]  **Basic dialog system**　可被 event 觸發的對話框；支援序列播放即可，不需複雜分支
- [ ]  Combat system refactor
    - [ ]  4 Attack module
- [ ]  Try to transform enemy to data-drive
- [ ]  Allies simple refactor to fit beehave and new module
- [ ]  **Summon system**　花費 soul 召喚；召喚槽 enable/disable 邏輯
- [ ]  Summary to doc and todo list
    - [ ]  Encounter system
    - [ ]  Despawn controller
    - [ ]  Spawn system
    - [ ]  Loot drop and pickups
    - [ ]  Enemy with data-drive and dynamic generate from EnemyData system

---

## Week 2 　3/19–3/25　Boss + Demo Flow

**目標：把完整 demo flow 串起來，龍 boss 製作，dialog 內容全部填入**

### 敵人 / 召喚物製作

- [ ]  **2 Enemy types build**　Slime、Skull、Bear 基本攻擊行為
- [ ]  **3 Summon types build**　Slime、Skull、Bear；設定 summon limits

### Dragon Boss

- [ ]  **Dragon boss — fire attack + charge/swipe**
- [ ]  **Dragon boss — death event**　觸發 unlock dialog → 解鎖龍召喚槽
- [ ]  **Dragon summon build**

### Demo Flow 串接

- [ ]  **Demo flow wiring**　把所有階段接起來：intro → soul tutorial → summon tutorial → objective waves → boss spawn → boss defeat → chaos ending
- [ ]  **所有 dialog 內容填入**　Intro dialog、soul/summon tutorial dialog、boss trigger dialog、dragon unlock dialog
- [ ]  **Soul 再生 enable（Dragon 階段）**　Dragon 擊殺我方單位後自動開啟 soul regen
- [ ]  **Chaos mode**　Spawn 頻率 + 範圍漸進放大；disable HP lock；讓玩家試玩龍 summon

---

## Week 3 　3/25–3/31　Polish + Build

**目標：品質收尾，確保 demo 從頭到尾能順跑**

- [ ]  **End-to-end demo walkthrough**　完整跑一遍 demo flow，驗證每個觸發點、dialog、unlock 序列正確
- [ ]  Sound Review
- [ ]  Particles Review or Merge to new VFX system
- [ ]  **Balance / spawn pacing**　每批 wave 的怪物數量和節奏；chaos mode 的放大曲線
- [ ]  Bug fixing
- [ ]  Build export
- [ ]  Itch page

---

## Demo Content Checklist

### Core Demo

- [ ]  Arena map — 1600×1600（完成）
- [ ]  Enemy spawn pacing
- [ ]  Basic enemy types（2–3 種）

### Army

- [ ]  Slime army
- [ ]  Archer army
- [ ]  Ork army
- [ ]  Summon limits

### Boss

- [ ]  Dragon boss
    - [ ]  Fire attack
    - [ ]  Charge / swipe
    - [ ]  Death event

---

## Demo Flow

### 1. Player Start Setup

- [ ]  Spawn player
- [ ]  鎖定玩家最低 HP 為 1 god mode（防止死亡）

### 2. Initial UI State

- [ ]  顯示召喚槽
- [ ]  所有召喚槽 disabled
- [ ]  Soul 為 0，召喚不可用

### 3. Intro Dialog

- [ ]  說明戰鬥基本操作
- [ ]  指示玩家摧毀箱子
- [ ]  箱子掉落 soul orbs

### 4. Soul 教學

- [ ]  Dialog：說明箱子或敵人都可能掉落 soul orbs
- [ ]  玩家吸收 soul, soul 補到滿
- [ ]  召喚槽解鎖變為可用

### 5. Summon 教學 Dialog

- [ ]  指示召喚 4 隻 Slime（花費 soul）
- [ ]  指示召喚 2 隻 Archer（花費 soul）
- [ ]  指示召喚 1 隻 Ork（花費 soul）

### 6. Objective 推進

- [ ]  擊殺敵人累積進度
- [ ]  達標後切換到下一批 spawn table（解鎖新怪物）
- [ ]  重複數波，直到解鎖 Dragon boss 戰

### 7. Boss 登場

- [ ]  Spawn Dragon boss
- [ ]  觸發 boss 登場 dialog

### 8. Dragon 展示段落

- [ ]  Dragon 擊殺多個我方 army 單位
- [ ]  開啟 soul 自動再生（讓玩家能補召喚）

### 9. 玩家 vs Boss

- [ ]  Dragon 攻擊玩家
- [ ]  玩家 HP 鎖定為 1（無法死亡）

### 10. Boss 擊敗

- [ ]  玩家擊敗 Dragon
- [ ]  觸發 Dragon unlock dialog

### 11. 解鎖龍召喚

- [ ]  啟用 Dragon 召喚槽

### 12. Demo 結尾 — Chaos Mode

- [ ]  解除 HP 鎖定
- [ ]  啟用 chaos spawn mode（spawn 頻率與範圍逐漸放大）
- [ ]  玩家可自由召喚 Dragon
- [ ]  讓玩家盡情屠殺，最後被怪物淹死收場
