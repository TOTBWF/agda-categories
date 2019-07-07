{-# OPTIONS --without-K --safe #-}
module Categories.Category.Product where

open import Level
open import Function using () renaming (_∘_ to _∙_)
open import Data.Product using (_×_; Σ; _,_; proj₁; proj₂; zip; map; <_,_>; swap)

open import Categories.Category.Core
open import Categories.Functor.Core renaming (id to idF)
open import Categories.NaturalTransformation.Core
open import Categories.NaturalTransformation.NaturalIsomorphism hiding (refl; sym; trans)
import Categories.Morphism as Morphism

-- "very dependent" versions of map and zipWith
private
  map⁎ : ∀ {a b p q} {A : Set a} {B : A → Set b} {P : A → Set p} {Q : {x : A} → P x → B x → Set q} →
        (f : (x : A) → B x) → (∀ {x} → (y : P x) → Q y (f x)) → (v : Σ A P) → Σ (B (proj₁ v)) (Q (proj₂ v))
  map⁎ f g (x , y) = (f x , g y)

  map⁎′ : ∀ {a b p q} {A : Set a} {B : A → Set b} {P : Set p} {Q : P → Set q} → (f : (x : A) → B x) → ((x : P) → Q x) → (v : A × P) → B (proj₁ v) × Q (proj₂ v)
  map⁎′ f g (x , y) = (f x , g y)

  zipWith : ∀ {a b c p q r s} {A : Set a} {B : Set b} {C : Set c} {P : A → Set p} {Q : B → Set q} {R : C → Set r} {S : (x : C) → R x → Set s} (_∙_ : A → B → C) → (_∘_ : ∀ {x y} → P x → Q y → R (x ∙ y)) → (_*_ : (x : C) → (y : R x) → S x y) → (x : Σ A P) → (y : Σ B Q) → S (proj₁ x ∙ proj₁ y) (proj₂ x ∘ proj₂ y)
  zipWith _∙_ _∘_ _*_ (a , p) (b , q) = (a ∙ b) * (p ∘ q)
  syntax zipWith f g h = f -< h >- g

private
  variable
    o ℓ e o′ ℓ′ e′ o″ ℓ″ e″ : Level
    o₁ ℓ₁ e₁ o′₁ ℓ′₁ e′₁ o₂ ℓ₂ e₂ o′₂ ℓ′₂ e′₂ : Level

    C C₁ C₂ D D₁ D₂ : Category o ℓ e

Product : ∀ (C : Category o ℓ e) (D : Category o′ ℓ′ e′) → Category (o ⊔ o′) (ℓ ⊔ ℓ′) (e ⊔ e′)
Product C D = record
  { Obj       = C.Obj × D.Obj
  ; _⇒_       = C._⇒_ -< _×_ >- D._⇒_
  ; _≈_       = C._≈_ -< _×_ >- D._≈_
  ; _∘_       = zip C._∘_ D._∘_
  ; id        = C.id , D.id
  ; assoc     = C.assoc , D.assoc
  ; identityˡ = C.identityˡ , D.identityˡ
  ; identityʳ = C.identityʳ , D.identityʳ
  ; equiv     = record
    { refl  = C.Equiv.refl , D.Equiv.refl
    ; sym   = map C.Equiv.sym D.Equiv.sym
    ; trans = zip C.Equiv.trans D.Equiv.trans
    }
  ; ∘-resp-≈  = zip C.∘-resp-≈ D.∘-resp-≈
  }
  where module C = Category C
        module D = Category D

-- product of functors sharing the same domain
infixr 2 _※_
_※_ : ∀ (F : Functor C D₁) → (G : Functor C D₂) → Functor C (Product D₁ D₂)
F ※ G = record
  { F₀           = < F.F₀ , G.F₀ >
  ; F₁           = < F.F₁ , G.F₁ >
  ; identity     = F.identity , G.identity
  ; homomorphism = F.homomorphism , G.homomorphism
  ; F-resp-≈     = < F.F-resp-≈ , G.F-resp-≈ >
  }
  where module F = Functor F
        module G = Functor G

-- general product of functors
infixr 2 _⁂_
_⁂_ : ∀ (F₁ : Functor C₁ D₁) (F₂ : Functor C₂ D₂) → Functor (Product C₁ C₂) (Product D₁ D₂)
F ⁂ G = record
  { F₀           = map F.F₀ G.F₀
  ; F₁           = map F.F₁ G.F₁
  ; identity     = F.identity , G.identity
  ; homomorphism = F.homomorphism , G.homomorphism
  ; F-resp-≈     = map F.F-resp-≈ G.F-resp-≈
  }
  where module F = Functor F
        module G = Functor G

-- Natural Transformations respect the ⁂ product
infixr 5 _⁂ⁿ_
_⁂ⁿ_ : ∀ {C₁ : Category o₁ ℓ₁ e₁} {D₁ : Category o′₁ ℓ′₁ e′₁}
         {C₂ : Category o₂ ℓ₂ e₂} {D₂ : Category o′₂ ℓ′₂ e′₂}
         {F₁ G₁ : Functor C₁ D₁} {F₂ G₂ : Functor C₂ D₂}
         (α : NaturalTransformation F₁ G₁) (β : NaturalTransformation F₂ G₂) →
         NaturalTransformation (F₁ ⁂ F₂) (G₁ ⁂ G₂)
α ⁂ⁿ β = record
  { η       = map⁎′ α.η β.η
  ; commute = map⁎′ α.commute β.commute
  }
  where module α = NaturalTransformation α
        module β = NaturalTransformation β

-- Natural Transformations respect the ※ product as well
infixr 5 _※ⁿ_
_※ⁿ_ : ∀ {D₁ : Category o ℓ e} {D₂ : Category o′ ℓ′ e′}
         {F₁ G₁ : Functor C D₁} {F₂ G₂ : Functor C D₂}
         (α : NaturalTransformation F₁ G₁) →
         (β : NaturalTransformation F₂ G₂) →
         NaturalTransformation (F₁ ※ F₂) (G₁ ※ G₂)
α ※ⁿ β = record
  { η       = < α.η , β.η >
  ; commute = < α.commute , β.commute >
  }
  where module α = NaturalTransformation α
        module β = NaturalTransformation β

-- Natural Isomorphisms too
infixr 5 _⁂ⁿⁱ_
_⁂ⁿⁱ_ : ∀ {C₁ : Category o₁ ℓ₁ e₁} {D₁ : Category o′₁ ℓ′₁ e′₁}
          {C₂ : Category o₂ ℓ₂ e₂} {D₂ : Category o′₂ ℓ′₂ e′₂}
          {F₁ G₁ : Functor C₁ D₁} {F₂ G₂ : Functor C₂ D₂}
          (α : NaturalIsomorphism F₁ G₁) (β : NaturalIsomorphism F₂ G₂) →
          NaturalIsomorphism (F₁ ⁂ F₂) (G₁ ⁂ G₂)
α ⁂ⁿⁱ β = record
  { F⇒G = α.F⇒G ⁂ⁿ β.F⇒G
  ; F⇐G = α.F⇐G ⁂ⁿ β.F⇐G
  ; iso = λ where
    (X , Y) → record
      { isoˡ = isoˡ (α.iso X) , isoˡ (β.iso Y)
      ; isoʳ = isoʳ (α.iso X) , isoʳ (β.iso Y)
      }
  }
  where module α = NaturalIsomorphism α
        module β = NaturalIsomorphism β
        open Morphism.Iso

-- Natural Isomorphisms too
infixr 5 _※ⁿⁱ_
_※ⁿⁱ_ : ∀ {D₁ : Category o ℓ e} {D₂ : Category o′ ℓ′ e′}
          {F₁ G₁ : Functor C D₁} {F₂ G₂ : Functor C D₂}
          (α : NaturalIsomorphism F₁ G₁) →
          (β : NaturalIsomorphism F₂ G₂) →
          NaturalIsomorphism (F₁ ※ F₂) (G₁ ※ G₂)
α ※ⁿⁱ β = record
  { F⇒G = α.F⇒G ※ⁿ β.F⇒G
  ; F⇐G = α.F⇐G ※ⁿ β.F⇐G
  ; iso = λ X → record
    { isoˡ = isoˡ (α.iso X) , isoˡ (β.iso X)
    ; isoʳ = isoʳ (α.iso X) , isoʳ (β.iso X)
    }
  }
  where module α = NaturalIsomorphism α
        module β = NaturalIsomorphism β
        open Morphism.Iso

-- constant object Functor -- move?
const : Category.Obj C → Functor D C
const {C = C} c = record
  { F₀           = λ _ → c
  ; F₁           = λ _ → Category.id C
  ; identity     = refl
  ; homomorphism = sym identityˡ
  ; F-resp-≈     = λ _ → refl
  }
  where open Category C
        open HomReasoning

constˡ : Category.Obj C → Functor D (Product C D)
constˡ c = const c ※ idF

constʳ : Category.Obj C → Functor D (Product D C)
constʳ c = idF ※ (const c)

module _ (C₁ : Category o ℓ e) (C₂ : Category o′ ℓ′ e′) (C₃ : Category o″ ℓ″ e″) where

  module C₁ = Category C₁
  module C₂ = Category C₂
  module C₃ = Category C₃

  assocˡ : Functor (Product (Product C₁ C₂) C₃) (Product C₁ (Product C₂ C₃))
  assocˡ = record
    { F₀           = < proj₁ ∙ proj₁ , < proj₂ ∙ proj₁ , proj₂ > >
    ; F₁           = < proj₁ ∙ proj₁ , < proj₂ ∙ proj₁ , proj₂ > >
    ; identity     = C₁.Equiv.refl , C₂.Equiv.refl , C₃.Equiv.refl
    ; homomorphism = C₁.Equiv.refl , C₂.Equiv.refl , C₃.Equiv.refl
    ; F-resp-≈     = < proj₁ ∙ proj₁ , < proj₂ ∙ proj₁ , proj₂ > >
    }

  assocʳ : Functor (Product C₁ (Product C₂ C₃)) (Product (Product C₁ C₂) C₃)
  assocʳ = record
    { F₀           = < < proj₁ , proj₁ ∙ proj₂ > , proj₂ ∙ proj₂ >
    ; F₁           = < < proj₁ , proj₁ ∙ proj₂ > , proj₂ ∙ proj₂ >
    ; identity     = (C₁.Equiv.refl , C₂.Equiv.refl) , C₃.Equiv.refl
    ; homomorphism = (C₁.Equiv.refl , C₂.Equiv.refl) , C₃.Equiv.refl
    ; F-resp-≈     = < < proj₁ , proj₁ ∙ proj₂ > , proj₂ ∙ proj₂ >
    }

module _ {C : Category o ℓ e} {D : Category o′ ℓ′ e′} where

  private
    module C = Category C
    module D = Category D

  πˡ : Functor (Product C D) C
  πˡ = record
    { F₀           = proj₁
    ; F₁           = proj₁
    ; identity     = refl
    ; homomorphism = refl
    ; F-resp-≈     = proj₁
    }
    where open C.Equiv using (refl)

  πʳ : Functor (Product C D) D
  πʳ = record
    { F₀           = proj₂
    ; F₁           = proj₂
    ; identity     = refl
    ; homomorphism = refl
    ; F-resp-≈     = proj₂
    }
    where open D.Equiv using (refl)

  Swap : Functor (Product C D) (Product D C)
  Swap = record
    { F₀           = swap
    ; F₁           = swap
    ; identity     = D.Equiv.refl , C.Equiv.refl
    ; homomorphism = D.Equiv.refl , C.Equiv.refl
    ; F-resp-≈     = swap
    }
