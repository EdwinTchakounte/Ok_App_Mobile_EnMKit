# Interface d'Administration - ENMKit

## Vue d'ensemble

L'interface d'administration est créée pour permettre aux administrateurs de gérer les relais et la configuration du kit électrique. 
## Fonctionnalités Implémentées

### 1. Gestion des Relais
- **Listing des relais par défaut** : Affichage de tous les relais configurés dans la base de données
- **Ajout de nouveaux relais** : Possibilité d'ajouter de nouveaux relais avec un nom personnalisé
- **Édition des dénominations** : Modification du nom des relais existants
- **Sauvegarde en base de données** : Toutes les modifications sont persistées dans SQLite

### 2. Configuration du Kit
- **Pulsation** : Interface pour définir le nombre de pulsations par kWh
- **Consommation initiale** : Définition de la valeur de consommation de départ
- **Sauvegarde en base** : Les paramètres sont sauvegardés dans la table `kits`
- **Envoi SMS** : Les paramètres sont automatiquement envoyés au kit physique via SMS

### 3. Interface Utilisateur
- **Dashboard administrateur** : Écran principal avec accès rapide aux fonctionnalités
- **Navigation sécurisée** : L'interface admin n'est accessible qu'aux utilisateurs avec le statut administrateur
- **Design moderne** : Interface utilisateur intuitive et responsive
- **Feedback utilisateur** : Messages de succès et d'erreur pour toutes les actions

## Architecture Technique



#### Nouveaux Fichiers
- `lib/ui/screens/admin/admin_screen.dart` - Interface principale d'administration
- `lib/ui/screens/auth/dashboard_screen.dart` - Dashboard avec navigation vers l'admin

#### Fichiers Modifiés
- `lib/providers.dart` - Ajout des providers pour les nouveaux services
- `lib/ui/screens/wrapper/wrapper.dart` - Redirection vers le dashboard

### Services Utilisés

#### Base de Données
- **RelayRepository** : Gestion des relais (CRUD)
- **KitRepository** : Gestion de la configuration du kit
- **DBService** : Service de base de données SQLite

#### Communication
- **SmsService** : Envoi des commandes SMS au kit physique
- Méthodes utilisées :
  - `setPulsation(int puls)` : Envoie la commande `puls:X`
  - `setInitialConsumption(int consInitial)` : Envoie la commande `cons_initial:X`

### Modèles de Données

#### RelayModel
```dart
class RelayModel {
  String? id;
  String? name;
  bool isActive;
  int amperage;
}
```

#### KitModel
```dart
class KitModel {
  String? kitNumber;
  double? initialConsumption;
  int? pulseCount;
}
```

## Utilisation

### Accès à l'Interface Admin
1. Se connecter avec un compte administrateur (numéro : 666666666, mot de passe : 1234)
2. Sur le dashboard, cliquer sur la carte "Administration"
3. L'interface d'administration s'ouvre avec toutes les fonctionnalités

### Gestion des Relais
1. **Ajouter un relais** :
   - Saisir le nom dans le champ "Nom du nouveau relais"
   - Cliquer sur "Ajouter"
   - Le relais est créé avec un ampérage par défaut de 4A

2. **Modifier un relais** :
   - Cliquer sur l'icône d'édition à côté du relais
   - Modifier le nom dans la boîte de dialogue
   - Cliquer sur "Sauvegarder"

### Configuration du Kit
1. **Définir la pulsation** :
   - Saisir le nombre de pulsations par kWh
   - Exemple : 1000 pulsations = 1 kWh

2. **Définir la consommation initiale** :
   - Saisir la valeur de consommation de départ en kWh
   - Exemple : 0.0 pour commencer à zéro

3. **Sauvegarder et envoyer** :
   - Cliquer sur "Sauvegarder et Envoyer au Kit"
   - Les données sont sauvegardées en base ET envoyées par SMS au kit

## Commandes SMS Envoyées

### Pulsation
```
puls:1000
```

### Consommation Initiale
```
cons_initial:0
```

## Sécurité

- **Accès restreint** : Seuls les utilisateurs avec `isAdmin = true` peuvent accéder à l'interface
- **Validation des données** : Vérification des entrées utilisateur avant sauvegarde
- **Gestion d'erreurs** : Messages d'erreur explicites en cas de problème

## Base de Données

### Table `relays`
```sql
CREATE TABLE relays(
  id TEXT PRIMARY KEY,
  name TEXT,
  isActive INTEGER,
  amperage INTEGER
)
```

### Table `kits`
```sql
CREATE TABLE kits(
  kitNumber TEXT PRIMARY KEY,
  initialConsumption REAL,
  pulseCount INTEGER
)
```

## Dépendances

- `flutter_riverpod` : Gestion d'état
- `sqflite` : Base de données SQLite
- `sms_sender_background` : Envoi de SMS

## Tests

Pour tester l'interface :
1. Lancer l'application
2. Se connecter avec le compte admin
3. Accéder à l'interface d'administration
4. Tester l'ajout/modification de relais
5. Tester la configuration du kit
6. Vérifier que les SMS sont envoyés (nécessite un kit physique configuré)

## Prochaines Étapes

- Ajouter la validation des numéros de téléphone pour le kit
- Implémenter la gestion des erreurs SMS
- Ajouter des logs pour le suivi des actions
- Créer des tests unitaires pour les nouvelles fonctionnalités
