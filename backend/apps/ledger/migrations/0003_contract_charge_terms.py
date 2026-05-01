from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('ledger', '0002_workflow_upgrade'),
    ]

    operations = [
        migrations.AddField(
            model_name='contract',
            name='optional_terms',
            field=models.JSONField(blank=True, default=list),
        ),
        migrations.AddField(
            model_name='contract',
            name='recurring_charges',
            field=models.JSONField(blank=True, default=list),
        ),
    ]
