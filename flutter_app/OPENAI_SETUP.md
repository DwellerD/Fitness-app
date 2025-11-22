# OpenAI API Setup Instructions

## Step 1: Get Your API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign up or log in
3. Click "Create new secret key"
4. Copy your API key (starts with `sk-`)

## Step 2: Configure API Key

### Option A: Environment File (Recommended for Development)

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and replace with your key:
   ```
   OPENAI_API_KEY=sk-your-actual-key-here
   ```

### Option B: Hardcode (NOT recommended - only for testing)

In `lib/main.dart`, add before `runApp()`:
```dart
OpenAIService.initialize('sk-your-actual-key-here');
```

## Step 3: Install Dependencies

```bash
flutter pub get
```

## Features Available:

✅ **Food Image Analysis** - GPT-4 Vision analyzes meal photos
✅ **AI Coach Chat** - 4 specialized coaches (nutrition, fitness, wellness, trainer)
✅ **Workout Plan Generation** - Personalized based on goals and equipment
✅ **Meal Plan Generation** - Custom plans based on macro targets

## Cost Estimates:

- **Food Analysis**: ~$0.01 per image (GPT-4 Vision)
- **Coach Chat**: ~$0.0001-0.001 per message (GPT-4o-mini)
- **Plan Generation**: ~$0.001-0.005 per plan (GPT-4o-mini)

## Security Notes:

⚠️ **Never commit your `.env` file to git**
⚠️ **For production, use secure backend API**
⚠️ **Consider rate limiting to control costs**

## Next Steps:

The OpenAI service is ready to use in:
- `add_meal_screen.dart` - for food analysis
- `avatars_screen.dart` - for coach conversations
- `plans_screen.dart` - for workout/meal generation
