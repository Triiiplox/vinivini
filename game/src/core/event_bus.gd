extends Node
## Barramento de eventos global. Camadas se comunicam por aqui sem se conhecer.

signal session_started
signal session_finished
signal activity_started(activity: Dictionary)
signal answer_submitted(activity_id: String, correct: bool)
signal answer_correct(activity_id: String, tries: int)
signal answer_incorrect(activity_id: String, tries: int)
signal challenge_completed(result: Dictionary)
signal skill_mastery_changed(skill_id: String, level: int, mastery: float)
signal skill_level_changed(skill_id: String, old_level: int, new_level: int)
signal reward_unlocked(item_id: String)
signal stars_changed(total: int)
signal story_choice_made(story_id: String, node_id: String, choice_index: int)
signal story_finished(story_id: String, ending_id: String)
signal avatar_changed(avatar: Dictionary)
signal settings_changed(key: String, value: Variant)
