
+     1: # Preventing Automatic System Reboots
+     2: 
+     3: ## Problem
+     4: The system was automatically rebooting due to the `needrestart` utility after package updates, causing loss of unsaved work.
+     5: 
+     6: ## Root Cause
+     7: - `needrestart` was configured in automatic mode
+     8: - Triggered by kernel/library updates requiring service restarts
+     9: - Occurred at 02:37:41 UTC on 2025-11-26, causing reboot at 02:40:02 UTC
+    10: 
+    11: ## Solution Applied
+    12: 
+    13: ### 1. Configure needrestart to List-Only Mode
+    14: ```bash
+    15: sudo sed -i 's/#$nrconf{restart} = '\''i'\'';/$nrconf{restart} = '\''l'\'';/' /etc/needrestart/needrestart.conf
+    16: ```
+    17: 
+    18: ### 2. Disable Kernel Reboot Hints
+    19: ```bash
+    20: sudo sed -i 's/#$nrconf{kernelhints} = -1;/$nrconf{kernelhints} = 0;/' /etc/needrestart/needrestart.conf
+    21: ```
+    22: 
+    23: ## Configuration Changes Made
+    24: 
+    25: **File**: `/etc/needrestart/needrestart.conf`
+    26: 
+    27: **Before**:
+    28: ```perl
+    29: #$nrconf{restart} = 'i';
+    30: #$nrconf{kernelhints} = -1;
+    31: ```
+    32: 
+    33: **After**:
+    34: ```perl
+    35: $nrconf{restart} = 'l';
+    36: $nrconf{kernelhints} = 0;
+    37: ```
+    38: 
+    39: ## Result
+    40: - System updates continue automatically
+    41: - Services needing restart are listed but not automatically restarted
+    42: - **No automatic reboots** - manual intervention required
+    43: - Use `sudo needrestart` to check what needs attention
+    44: 
+    45: ## Verification
+    46: Unattended-upgrades already configured correctly:
+    47: ```
+    48: //Unattended-Upgrade::Automatic-Reboot "false";
+    49: ```
+    50: 
+    51: ## Manual Restart Check
+    52: To see what needs restarting after updates:
+    53: ```bash
+    54: sudo needrestart
+    55: ```
