from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ('ledger', '0003_contract_charge_terms'),
    ]

    operations = [
        migrations.AddField(
            model_name='transaction',
            name='charge_label',
            field=models.CharField(blank=True, default='', max_length=128),
        ),
        migrations.AlterField(
            model_name='transaction',
            name='transaction_type',
            field=models.CharField(
                choices=[
                    ('rent', 'Rent'),
                    ('electricity', 'Electricity'),
                    ('water', 'Water'),
                    ('waste_management', 'Waste Management'),
                    ('internet', 'Internet'),
                    ('other', 'Other'),
                ],
                max_length=32,
            ),
        ),
    ]
