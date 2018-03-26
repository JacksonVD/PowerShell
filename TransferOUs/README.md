# Transfer OUs
A PowerShell script to take in OU information, and migrate the given OUs to a new domain.

REQUIRES: Needs to be run on the target PDC - requires admt, ldifde, and the AD PowerShell module
NOTE: Adding computer records from OUs may be unsafe - will restart the PCs if in use, need to find a way to more robustly move PCs
