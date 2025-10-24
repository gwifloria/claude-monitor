## Completed

1. ✅ 到达 time limit 后,会话不会被中断，持续显示 processing
   - **Fixed**: Added processing timeout detection in `clean_expired_completed()`
   - Processing status now auto-expires to idle after 30 minutes without updates
   - Handles scenarios where ClaudeCode reaches time limit but process remains alive
   - See: lib/status_manager.sh:129
