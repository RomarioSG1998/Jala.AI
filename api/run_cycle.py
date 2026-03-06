import asyncio

from telegram_bot import StudySecretaryBot


def main() -> None:
    bot = StudySecretaryBot()
    asyncio.run(bot.run_scheduled_cycle())


if __name__ == "__main__":
    main()
