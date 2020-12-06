# Guesses on DataCartons
## The binary string before the begginig of a DataCarton
   Was this marked by marker or constant block size (before </PARAMOBJ>?
   No. It is especially different in size when it comes to the important DataCartons. Seems that the data is squeezed between tagged regions

# The markup language
## <PARAMOBJ></PARAMOBJ> was the highest level.
   - \0x3c / '<' was way too abundant. Parsing starting with that withought limiting the possible tags or tag lengths could be vulnerable to wierd non-stop cases
   - End of tag is always >(\0x3E)\0x0D\0x0A though