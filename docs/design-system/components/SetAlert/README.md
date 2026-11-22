# SetAlert

What happens when a set's bell rings. Outside the app it is the set notification: Time Sensitive, title "[reps] now", body "Set [n] of [total] · Day [d]", and two actions in this order: **Done**, then **In 10 min**. iOS draws that card in its own colors; the app sets only the words and the icon.

- Done comes first so Apple Watch Double Tap logs the set.
- In the app and on the Watch set screen, the ring is the flood: the whole screen turns `flood`, a dark olive tint. The number and bell icon are `volt`, the eyebrow and caption are `flood-soft`, Done is the usual `volt` fill with `on-volt` text, and In 10 min has a `flood-soft` outline with `ink` text.
- With Reduce Motion on, the flood shows with no animation.
