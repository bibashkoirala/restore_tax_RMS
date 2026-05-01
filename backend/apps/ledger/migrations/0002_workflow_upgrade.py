import re

from django.db import migrations, models
import django.db.models.deletion


def _slugify_username(name):
    slug = re.sub(r'[^a-z0-9]+', '_', name.lower()).strip('_')
    return slug or 'user'


def populate_party_usernames(apps, schema_editor):
    Party = apps.get_model('ledger', 'Party')
    for party in Party.objects.all().order_by('id'):
        if party.username:
            continue
        party.username = f'{_slugify_username(party.name)}_{party.id}'
        party.save(update_fields=['username'])


class Migration(migrations.Migration):
    dependencies = [
        ('ledger', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='party',
            name='username',
            field=models.CharField(blank=True, max_length=64, null=True, unique=True),
        ),
        migrations.RunPython(populate_party_usernames, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='party',
            name='username',
            field=models.CharField(max_length=64, unique=True),
        ),
        migrations.AddField(
            model_name='contract',
            name='approved_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='contract',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending_approval', 'Pending Approval'),
                    ('active', 'Active'),
                    ('expired', 'Expired'),
                ],
                default='pending_approval',
                max_length=32,
            ),
        ),
        migrations.AlterField(
            model_name='contract',
            name='code',
            field=models.CharField(blank=True, max_length=64, unique=True),
        ),
        migrations.AddField(
            model_name='transaction',
            name='approved_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='transaction',
            name='approved_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name='approved_transactions',
                to='ledger.party',
            ),
        ),
        migrations.AddField(
            model_name='transaction',
            name='claimed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='transaction',
            name='claimed_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name='claimed_transactions',
                to='ledger.party',
            ),
        ),
        migrations.AlterField(
            model_name='transaction',
            name='status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('claimed', 'Claimed'),
                    ('approved', 'Approved'),
                    ('failed', 'Failed'),
                    ('disputed', 'Disputed'),
                ],
                default='pending',
                max_length=32,
            ),
        ),
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=255)),
                ('message', models.TextField()),
                ('notification_type', models.CharField(choices=[('contract_approval', 'Contract Approval'), ('transaction_claimed', 'Transaction Claimed'), ('transaction_approved', 'Transaction Approved'), ('system', 'System')], default='system', max_length=32)),
                ('is_read', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('contract', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='ledger.contract')),
                ('recipient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='ledger.party')),
                ('transaction', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to='ledger.transaction')),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
