# TCG Arena - Backend Spring Boot Documentation

Basandomi sull'analisi completa del progetto iOS TCG Arena, ecco una documentazione dettagliata per creare il backend Spring Boot che supporti tutte le funzionalità dell'app.

## 📋 Panoramica del Progetto

TCG Arena è un'applicazione iOS per collezionisti di carte da gioco (Trading Card Games) che supporta:
- **Pokemon TCG**
- **One Piece TCG**
- **Magic: The Gathering**
- **Yu-Gi-Oh!**
- **Digimon TCG**

### 🏗️ Architettura Backend

```
Spring Boot Backend
├── Spring Security (JWT Authentication)
├── Spring Data JPA (PostgreSQL/MySQL)
├── Spring Web (REST APIs)
├── Spring Cloud (Config, Discovery)
├── Redis (Caching & Sessions)
├── AWS S3 (File Storage)
└── Firebase Integration (Notifications)
```

## 🗄️ Modello dei Dati

### 1. User (Utente)

```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(unique = true, nullable = false)
    private String username;

    @Column(nullable = false)
    private String displayName;

    private String profileImageUrl;

    @Column(nullable = false)
    private LocalDateTime dateJoined;

    @Column(nullable = false)
    private Boolean isPremium = false;

    @Enumerated(EnumType.STRING)
    private TCGType favoriteGame;

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "location_id")
    private UserLocation location;

    // Getters, Setters, Constructors
}

@Embeddable
public class UserLocation {
    private String city;
    private String country;
    private Double latitude;
    private Double longitude;

    // Getters, Setters, Constructors
}
```

### 2. TCGSet (Set di Carte)

```java
@Entity
@Table(name = "tcg_sets")
public class TCGSet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String setCode;

    private String imageUrl;

    @Column(nullable = false)
    private LocalDateTime releaseDate;

    @Column(nullable = false)
    private Integer cardCount;

    @Column(length = 1000)
    private String description;

    @ManyToOne
    @JoinColumn(name = "expansion_id")
    private Expansion expansion;

    // Getters, Setters, Constructors
}
```

### 3. Expansion (Espansione)

```java
@Entity
@Table(name = "expansions")
public class Expansion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TCGType tcgType;

    private String imageUrl;

    @OneToMany(mappedBy = "expansion", cascade = CascadeType.ALL)
    private List<TCGSet> sets = new ArrayList<>();

    // Computed fields (handled in service layer)
    @Transient
    public LocalDateTime getReleaseDate() {
        return sets.stream()
            .map(TCGSet::getReleaseDate)
            .max(LocalDateTime::compareTo)
            .orElse(LocalDateTime.now());
    }

    @Transient
    public int getCardCount() {
        return sets.stream()
            .mapToInt(TCGSet::getCardCount)
            .sum();
    }

    // Getters, Setters, Constructors
}
```

### 4. Card (Carta)

```java
@Entity
@Table(name = "cards")
public class Card {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TCGType tcgType;

    @Column(nullable = false)
    private String setCode;

    @ManyToOne
    @JoinColumn(name = "expansion_id")
    private Expansion expansion;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Rarity rarity;

    @Column(nullable = false)
    private String cardNumber;

    @Column(length = 2000)
    private String description;

    private String imageUrl;
    private Double marketPrice;
    private Integer manaCost;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CardCondition condition;

    @Column(nullable = false)
    private Boolean isGraded = false;

    @Enumerated(EnumType.STRING)
    private GradeService gradeService;

    private Integer gradeScore;

    @Column(nullable = false)
    private LocalDateTime dateAdded;

    @Column(nullable = false)
    private Long ownerId;

    private Long deckId;

    // Getters, Setters, Constructors
}
```

### 5. Deck (Mazzo)

```java
@Entity
@Table(name = "decks")
public class Deck {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TCGType tcgType;

    @Column(nullable = false)
    private Long ownerId;

    @Column(nullable = false)
    private LocalDateTime dateCreated;

    @Column(nullable = false)
    private LocalDateTime dateModified;

    @Column(nullable = false)
    private Boolean isPublic = false;

    @Column(length = 1000)
    private String description;

    @ElementCollection
    @CollectionTable(name = "deck_tags")
    private List<String> tags = new ArrayList<>();

    @OneToMany(mappedBy = "deck", cascade = CascadeType.ALL)
    private List<DeckCard> cards = new ArrayList<>();

    // Getters, Setters, Constructors
}

@Entity
@Table(name = "deck_cards")
public class DeckCard {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "deck_id", nullable = false)
    private Deck deck;

    @Column(nullable = false)
    private Long cardId;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false)
    private String cardName;

    private String cardImageUrl;

    // Getters, Setters, Constructors
}
```

### 6. Tournament (Torneo)

```java
@Entity
@Table(name = "tournaments")
public class Tournament {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(length = 2000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TCGType tcgType;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TournamentType type;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TournamentStatus status;

    @Column(nullable = false)
    private LocalDateTime startDate;

    @Column(nullable = false)
    private LocalDateTime endDate;

    @Column(nullable = false)
    private Integer maxParticipants;

    @Column(nullable = false)
    private Double entryFee;

    @Column(nullable = false)
    private Double prizePool;

    @Column(nullable = false)
    private Long organizerId;

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "location_id")
    private TournamentLocation location;

    @OneToMany(mappedBy = "tournament", cascade = CascadeType.ALL)
    private List<TournamentParticipant> participants = new ArrayList<>();

    // Getters, Setters, Constructors
}
```

### 7. Shop (Negozio)

```java
@Entity
@Table(name = "shops")
public class Shop {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(length = 1000)
    private String description;

    @Column(nullable = false)
    private String address;

    private Double latitude;
    private Double longitude;

    private String phoneNumber;
    private String websiteUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ShopType type;

    @Column(nullable = false)
    private Boolean isVerified = false;

    @Column(nullable = false)
    private Long ownerId;

    @OneToMany(mappedBy = "shop", cascade = CascadeType.ALL)
    private List<ShopInventory> inventory = new ArrayList<>();

    // Getters, Setters, Constructors
}
```

### 8. Enums e Tipi

```java
public enum TCGType {
    POKEMON("Pokemon"),
    ONE_PIECE("One Piece"),
    MAGIC("Magic: The Gathering"),
    YUGIOH("Yu-Gi-Oh!"),
    DIGIMON("Digimon");

    private final String displayName;

    TCGType(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

public enum Rarity {
    COMMON, UNCOMMON, RARE, HOLOGRAPHIC, SECRET, ULTRA_SECRET
}

public enum CardCondition {
    POOR, FAIR, GOOD, VERY_GOOD, NEAR_MINT, MINT
}

public enum GradeService {
    PSA, BGS, SGC
}

public enum TournamentType {
    CASUAL, COMPETITIVE, CHAMPIONSHIP
}

public enum TournamentStatus {
    UPCOMING, REGISTRATION_OPEN, REGISTRATION_CLOSED, IN_PROGRESS, COMPLETED, CANCELLED
}

public enum ShopType {
    LOCAL_STORE, ONLINE_STORE, MARKETPLACE
}
```

## 🔐 Sicurezza e Autenticazione

### JWT Authentication

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    private JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    @Autowired
    private UserDetailsService jwtUserDetailsService;

    @Autowired
    private JwtRequestFilter jwtRequestFilter;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .authorizeRequests()
            .antMatchers("/api/auth/**").permitAll()
            .antMatchers("/api/public/**").permitAll()
            .anyRequest().authenticated()
            .and()
            .exceptionHandling().authenticationEntryPoint(jwtAuthenticationEntryPoint)
            .and()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS);

        http.addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);
    }
}
```

## 🛠️ API Endpoints

### Authentication APIs
```
POST   /api/auth/login
POST   /api/auth/register
POST   /api/auth/refresh-token
POST   /api/auth/forgot-password
POST   /api/auth/reset-password
```

### User APIs
```
GET    /api/users/profile
PUT    /api/users/profile
GET    /api/users/{id}
GET    /api/users/search
GET    /api/users/leaderboard
```

### Card APIs
```
GET    /api/cards
GET    /api/cards/{id}
POST   /api/cards
PUT    /api/cards/{id}
DELETE /api/cards/{id}
GET    /api/cards/collection/{userId}
POST   /api/cards/{id}/add-to-collection
GET    /api/cards/market-price/{id}
```

### Deck APIs
```
GET    /api/decks
GET    /api/decks/{id}
POST   /api/decks
PUT    /api/decks/{id}
DELETE /api/decks/{id}
POST   /api/decks/{id}/add-card
DELETE /api/decks/{id}/remove-card
GET    /api/decks/public
```

### Expansion & Set APIs
```
GET    /api/expansions
GET    /api/expansions/{id}
GET    /api/expansions/recent
GET    /api/sets
GET    /api/sets/{id}
GET    /api/sets/code/{setCode}/cards
```

### Tournament APIs
```
GET    /api/tournaments
GET    /api/tournaments/{id}
POST   /api/tournaments
PUT    /api/tournaments/{id}
DELETE /api/tournaments/{id}
POST   /api/tournaments/{id}/join
POST   /api/tournaments/{id}/leave
GET    /api/tournaments/nearby
```

### Shop APIs
```
GET    /api/shops
GET    /api/shops/{id}
POST   /api/shops
PUT    /api/shops/{id}
GET    /api/shops/nearby
GET    /api/shops/{id}/inventory
```

### Rewards APIs
```
GET    /api/rewards
GET    /api/rewards/{id}
POST   /api/rewards/{id}/claim
GET    /api/rewards/points/{userId}
POST   /api/rewards/points/add
GET    /api/rewards/partners
```

## 📊 Servizi Business

### 1. CardService
```java
@Service
public class CardService {
    @Autowired
    private CardRepository cardRepository;

    @Autowired
    private TCGApiClient tcgApiClient; // External API client

    public List<Card> getUserCollection(Long userId) {
        return cardRepository.findByOwnerId(userId);
    }

    public Card addCardToCollection(Card card, Long userId) {
        card.setOwnerId(userId);
        card.setDateAdded(LocalDateTime.now());
        return cardRepository.save(card);
    }

    public void updateMarketPrices() {
        // Update market prices from external APIs
        List<Card> cards = cardRepository.findAll();
        for (Card card : cards) {
            Double marketPrice = tcgApiClient.getMarketPrice(card.getName(), card.getSetCode());
            card.setMarketPrice(marketPrice);
        }
        cardRepository.saveAll(cards);
    }
}
```

### 2. DeckService
```java
@Service
public class DeckService {
    @Autowired
    private DeckRepository deckRepository;

    @Autowired
    private DeckCardRepository deckCardRepository;

    public Deck createDeck(String name, TCGType tcgType, Long ownerId) {
        Deck deck = new Deck();
        deck.setName(name);
        deck.setTcgType(tcgType);
        deck.setOwnerId(ownerId);
        deck.setDateCreated(LocalDateTime.now());
        deck.setDateModified(LocalDateTime.now());
        return deckRepository.save(deck);
    }

    public Deck addCardToDeck(Long deckId, Long cardId, int quantity) {
        Deck deck = deckRepository.findById(deckId)
            .orElseThrow(() -> new ResourceNotFoundException("Deck not found"));

        Card card = cardRepository.findById(cardId)
            .orElseThrow(() -> new ResourceNotFoundException("Card not found"));

        DeckCard deckCard = new DeckCard();
        deckCard.setDeck(deck);
        deckCard.setCardId(cardId);
        deckCard.setQuantity(quantity);
        deckCard.setCardName(card.getName());
        deckCard.setCardImageUrl(card.getImageUrl());

        deckCardRepository.save(deckCard);
        deck.getCards().add(deckCard);
        deck.setDateModified(LocalDateTime.now());

        return deckRepository.save(deck);
    }
}
```

### 3. TournamentService
```java
@Service
public class TournamentService {
    @Autowired
    private TournamentRepository tournamentRepository;

    @Autowired
    private TournamentParticipantRepository participantRepository;

    public List<Tournament> getNearbyTournaments(double latitude, double longitude, double radiusKm) {
        // Calculate distance using Haversine formula
        List<Tournament> allTournaments = tournamentRepository.findUpcomingTournaments();
        return allTournaments.stream()
            .filter(tournament -> {
                if (tournament.getLocation() == null) return false;
                double distance = calculateDistance(
                    latitude, longitude,
                    tournament.getLocation().getLatitude(),
                    tournament.getLocation().getLongitude()
                );
                return distance <= radiusKm;
            })
            .collect(Collectors.toList());
    }

    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        // Haversine formula implementation
        final int R = 6371; // Radius of the earth in km

        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
            + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
            * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distance = R * c;

        return distance;
    }
}
```

## 🗃️ Repository Layer

### Esempi di Repository

```java
@Repository
public interface CardRepository extends JpaRepository<Card, Long> {
    List<Card> findByOwnerId(Long ownerId);
    List<Card> findByTcgType(TCGType tcgType);
    List<Card> findBySetCode(String setCode);
    List<Card> findByOwnerIdAndTcgType(Long ownerId, TCGType tcgType);

    @Query("SELECT c FROM Card c WHERE c.ownerId = :ownerId AND c.deckId IS NULL")
    List<Card> findUnassignedCardsByOwnerId(@Param("ownerId") Long ownerId);
}

@Repository
public interface DeckRepository extends JpaRepository<Deck, Long> {
    List<Deck> findByOwnerId(Long ownerId);
    List<Deck> findByIsPublicTrue();
    List<Deck> findByTcgType(TCGType tcgType);
    List<Deck> findByOwnerIdAndTcgType(Long ownerId, TCGType tcgType);
}

@Repository
public interface TournamentRepository extends JpaRepository<Tournament, Long> {
    @Query("SELECT t FROM Tournament t WHERE t.startDate > :now ORDER BY t.startDate")
    List<Tournament> findUpcomingTournaments(@Param("now") LocalDateTime now);

    List<Tournament> findByStatus(TournamentStatus status);
    List<Tournament> findByOrganizerId(Long organizerId);
}
```

## 🔄 DTOs e Response Objects

### CardDTO
```java
public class CardDTO {
    private Long id;
    private String name;
    private TCGType tcgType;
    private String setCode;
    private ExpansionDTO expansion;
    private Rarity rarity;
    private String cardNumber;
    private String description;
    private String imageUrl;
    private Double marketPrice;
    private Integer manaCost;
    private CardCondition condition;
    private Boolean isGraded;
    private GradeService gradeService;
    private Integer gradeScore;
    private LocalDateTime dateAdded;

    // Constructor, Getters, Setters
}
```

### UserProfileDTO
```java
public class UserProfileDTO {
    private Long id;
    private String username;
    private String displayName;
    private String avatarUrl;
    private String bio;
    private LocalDateTime joinDate;
    private LocalDateTime lastActiveDate;
    private Boolean isVerified;
    private Integer level;
    private Integer experience;
    private UserStatsDTO stats;
    private List<UserBadgeDTO> badges;
    private String favoriteCard;
    private TCGType preferredTCG;
    private UserLocation location;
    private Integer followersCount;
    private Integer followingCount;
    private Boolean isFollowedByCurrentUser;

    // Constructor, Getters, Setters
}
```

## ⚙️ Configurazioni

### application.yml
```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/tcg_arena
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true

  redis:
    host: localhost
    port: 6379
    password: ${REDIS_PASSWORD}

jwt:
  secret: ${JWT_SECRET}
  expiration: 86400000  # 24 hours

aws:
  s3:
    bucket-name: ${AWS_S3_BUCKET}
    region: ${AWS_REGION}
    access-key: ${AWS_ACCESS_KEY}
    secret-key: ${AWS_SECRET_KEY}

external-apis:
  pokemon-tcg: ${POKEMON_TCG_API_KEY}
  magic-api: ${MAGIC_API_KEY}
```

## 🚀 Deployment

### Docker Compose
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: tcg_arena
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: docker
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
```

## 📈 Monitoraggio e Logging

### Health Check Endpoint
```java
@RestController
public class HealthController {
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        return ResponseEntity.ok(health);
    }
}
```

Questa documentazione fornisce una base completa per sviluppare il backend Spring Boot di TCG Arena. Include tutti i modelli di dati, API endpoints, servizi business e configurazioni necessarie per supportare le funzionalità dell'app iOS.</content>
<parameter name="filePath">/Users/PATRIZIO.PEZZILLI/Documents/Personale/TCG Arena - iOS App/TCG Arena/BACKEND_DOCUMENTATION.md