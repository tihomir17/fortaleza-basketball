# Generated manually to add sequence fields back to Possession model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("possessions", "0006_alter_possession_options_and_more"),
    ]

    operations = [
        migrations.AddField(
            model_name="possession",
            name="offensive_sequence",
            field=models.TextField(
                blank=True,
                help_text="Sequence of offensive actions",
                default=""
            ),
        ),
        migrations.AddField(
            model_name="possession",
            name="defensive_sequence",
            field=models.TextField(
                blank=True,
                help_text="Sequence of defensive actions",
                default=""
            ),
        ),
    ]
