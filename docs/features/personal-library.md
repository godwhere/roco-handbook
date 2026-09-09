# Personal library

## Storage and identity

The App stores favorites, collection marks, and notes in a private `user.db` that is independent from the replaceable Catalog. Every saved reference includes the dataset, stable object type and ID, and a name snapshot. No personal table has a foreign key into `catalog.db`.

Personal data is local to the device. It is not attached to an account, synchronized to a cloud service, or protected from App uninstall or operating-system data removal.

## Favorites

Creature favorites target a concrete `petId`, including the currently displayed form. Skill favorites target a `skillId`. Heart controls are available in lists and detail views.

The control sends the intended final state rather than toggling a database value. The UI changes after a successful transaction; on failure it keeps the previous state and offers a retry message. Repeating the same operation does not create duplicate rows.

## Collection marks

The **Handbook entry collected** control targets a `handbookId`. It is deliberately separate from a creature favorite and does not assert that every special form belonging to the entry is owned.

The **Collected** tab lists handbook entries, while the **Favorites** tab lists concrete creatures and skills.

## Notes

Creature and skill detail pages provide a device-local note editor. Saving a new note creates a stable note ID; editing preserves that ID and object ownership. Notes can be edited or deleted.

The editor clears only after a successful save. If the write fails, its full draft remains in the editor and a retry message is shown. Note contents are not written to diagnostic logs.

## Missing Catalog objects

My Library resolves saved IDs through the current Catalog. When an object is unavailable, the App shows its saved name snapshot, object type, stable ID, and an explicit **Currently unavailable in this Catalog** notice. The personal record is not deleted, and its notes remain available for editing or removal.

## Settings information

Settings shows App, Catalog, and personal schema versions, source revision range, build time, attribution, and the local-storage and uninstall warning. Theme currently follows the device setting.
