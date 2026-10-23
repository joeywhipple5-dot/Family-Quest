FAMILY QUEST — CHARACTER TEST BRANCH PACK (Godot 4.3)
=====================================================

This is a SEPARATE, isolated test project package. It does not modify the working Family Quest game.

Contains:
- Original supplied human FBX assets, textures and Idle/Walk/Run FBX animation files.
- Warrior.tscn, Mage.tscn, Rogue.tscn, Druid.tscn and Ranger.tscn.
- FamilyQuestHero.gd shared test loader.
- project.godot for opening this as a standalone Godot test project.

IMPORTANT LIMITATION:
This is the first safe import test, not a finished class outfit implementation. The scenes currently load the base human only. The clothing FBXs are included but deliberately not attached until their skeleton, mesh names, materials, and Godot import behavior are verified. No weapons or shields are equipped. Male/Female is an exported setting but body-specific selection has not been verified.

HOW TO TEST:
1. Keep this ZIP separate from your working repository.
2. Extract it into a new GitHub repository or a new branch folder named FamilyQuest-Character-Test.
3. Open in Godot 4.3 (or use your existing Android/GitHub workflow only after assets are committed to a separate test branch).
4. Let Godot import the FBX files. Open Warrior.tscn first.
5. If import errors appear or the body does not show, send the error screenshot. Do not merge this into main.
6. Once the base human loads, clothing and animation attachment can be done using the actual imported node/skeleton names.

LICENSE:
The original uploaded Unity package archive did not contain a license file. Confirm the creator's license before publishing or shipping these assets.
