# Interfaces sugeridas

ProgressRepository
- load_profile(profile_id)
- save_profile(profile)
- get_skill_progress(profile_id, skill_id)
- save_skill_progress(progress)
- save_attempt(attempt)

InventoryRepository
- unlock_item(profile_id, item_id)
- equip_item(profile_id, item_id)
- list_items(profile_id)

ContentRepository
- get_activity(skill_id, difficulty)
- get_story(story_id)
