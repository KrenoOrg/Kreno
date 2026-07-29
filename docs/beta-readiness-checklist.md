# Checklist de mise en bêta — 1er septembre 2026

## À vérifier avant d’inviter le premier professionnel

- [ ] Le projet Supabase distant est lié et la migration a été relue puis appliquée.
- [ ] Les politiques RLS ont été testées avec deux comptes professionnels.
- [ ] Les secrets Stripe et SMS sont configurés uniquement côté serveur.
- [ ] Les fonctions Edge sont déployées et leurs journaux sont accessibles.
- [ ] Le webhook Stripe est signé, configuré et testé sur un paiement d’essai.
- [ ] Le fournisseur SMS est choisi et un vrai SMS de test est reçu.
- [ ] Le mot STOP bloque effectivement les envois ultérieurs.
- [ ] Les pages confidentialité, CGU/CGV et contact sont publiées après relecture juridique.

## Recette fonctionnelle

Utiliser `docs/e2e-beta-script.md` pour consigner les résultats.

- [ ] Un professionnel crée son compte, choisit une formule et configure ses prestations.
- [ ] Un client rejoint une liste avec une date précise et un consentement SMS explicite.
- [ ] Un créneau libéré ne cible que les clients compatibles.
- [ ] Deux réponses simultanées à une même offre ne peuvent pas toutes deux gagner.
- [ ] Une offre expirée remet le client en attente.
- [ ] L’annulation d’un créneau restaure les demandes non confirmées.
- [ ] Les limites Solo, Pro et Business sont testées.
- [ ] L’espace prestataire ne laisse jamais voir les données d’un autre établissement.

## Bêta privée

- [ ] 3 à 5 professionnels pilotes ont accepté les conditions de test.
- [x] Le canal de support bêta est défini : kreno.contactfr@gmail.com.
- [ ] Chaque pilote possède une date de point hebdomadaire.
- [ ] Les métriques sont relevées chaque semaine : créneaux signalés, offres, réponses, confirmations, incidents et coût SMS.
- [ ] Toute erreur de paiement, SMS ou attribution possède un responsable et une procédure de résolution.
