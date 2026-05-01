from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('ledger', '0004_transaction_charge_label'),
    ]

    operations = [
        migrations.CreateModel(
            name='LandlordClientRelation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('client', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='client_links', to='ledger.party')),
                ('landlord', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='landlord_links', to='ledger.party')),
            ],
            options={
                'ordering': ['landlord__name', 'client__name'],
            },
        ),
        migrations.AddField(
            model_name='party',
            name='clients',
            field=models.ManyToManyField(related_name='landlords', symmetrical=False, through='ledger.LandlordClientRelation', to='ledger.party'),
        ),
        migrations.AddConstraint(
            model_name='landlordclientrelation',
            constraint=models.UniqueConstraint(fields=('landlord', 'client'), name='unique_landlord_client_relation'),
        ),
    ]
