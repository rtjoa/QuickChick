From ExtLib.Structures Require Export
     Monads.
From ExtLib.Structures Require Import
     Functor Applicative.
From QuickChick Require Import RoseTrees.
Require Import List.
Import ListNotations.

Import MonadNotation.
Open Scope monad_scope.


(* A lazy list *)
Inductive LazyList (A : Type) : Type :=
| lnil : LazyList A
| lcons : A -> (unit -> (LazyList A)) -> LazyList A.

Fixpoint lazy_append {A : Type} (l1 : LazyList A) (l2 : LazyList A) : LazyList A :=
  match l1 with
  | lnil => l2
  | lcons x l1' => lcons _ x (fun _ => (lazy_append (l1' tt) l2))
  end.

Fixpoint lazy_take {A : Type} (n : nat) (l : LazyList A) : LazyList A :=
  match n with
  | 0 => lnil _
  | S n' => match l with
           | lnil => lnil _
           | lcons h ts => lcons _ h (fun _ => (lazy_take n' (ts tt)))
           end
  end.

(* Functor instace for LazyList *)
Fixpoint mapLazyList {A B : Type} (f : A -> B) (l : LazyList A) : LazyList B :=
  match l with
  | lnil => lnil _
  | lcons x l' => lcons _ (f x) (fun _ => (mapLazyList f (l' tt)))
  end.

Instance FunctorLazyList : Functor LazyList :=
  {
    fmap := @mapLazyList
  }.


(* Monad and applicative instances for LazyList *)
Definition retLazyList {A : Type} (a : A) : LazyList A :=
  lcons _ a (fun _ => (lnil _)).

Fixpoint concatLazyList {A : Type} (l : LazyList (LazyList A)) : LazyList A :=
  match l with
  | lnil => lnil _
  | lcons x l' => lazy_append x (concatLazyList (l' tt))
  end.

Definition bindLazyList {A B : Type} (l : LazyList A) (f : A -> LazyList B) : LazyList B :=
  concatLazyList (mapLazyList f l).

Instance MonadLazyList : Monad LazyList :=
  {
    ret := @retLazyList;
    bind := @bindLazyList
  }.


Definition apLazyList {A B : Type} (lab : LazyList (A -> B)) (la : LazyList A) : LazyList B :=
  ab <- lab;;
  a <- la;;
  ret (ab a).


Instance ApplicativeLazyList : Applicative LazyList :=
  {
    pure := @retLazyList;
    ap := @apLazyList
  }.

Definition apComp {F: Type -> Type} `{Functor F} {A B C : Type} (f : B -> C) (fab : F (A -> B)) : F (A -> C) :=
  fmap (fun g => fun a => f (g a)) fab.


(* Guard definition, because ExtLib doesn't have Alternative *)
Definition guard (b : bool) : LazyList unit :=
  match b with
  | true => ret tt
  | false => lnil _
  end.


(* Lazy list in *)
Fixpoint In_ll {A : Type} (a : A) (l : LazyList A) : Prop :=
  match l with
  | lnil => False
  | lcons h ts => h = a \/ In_ll a (ts tt)
  end.

(*
Section Ind.
  Variable A : Type.
  Variable P : LazyList A -> Prop.
  Variable Hnil : P (lnil A).
  Variable Hcons : forall (a : A) (l : LazyList A), P l -> P (lcons _ a (fun _ => l)).

  Fixpoint better_ll_ind (l : LazyList A) : P l :=
    match l with
    | lnil => Hnil
    | lcons a tl => @Hcons a (tl tt) (better_ll_ind ( tl tt))
    end.
End Ind.

Lemma lazy_in_app_or :
  forall (A : Type) (l m : LazyList A) (a : A), In_ll a (lazy_append l m) -> In_ll a l \/ In_ll a m.
Proof.
  intros A l.
  induction l using better_ll_ind; intros m h H.
  - simpl in H. auto.
  - simpl in H. destruct H.
    + subst. simpl. auto.
    + simpl. rewrite or_assoc. right.
      auto.
Qed.

Lemma lazy_in_or_app :
  forall (A : Type) (l m : LazyList A) (a : A), In_ll a l \/ In_ll a m -> In_ll a (lazy_append l m).
Proof.
  intros A l.
  induction l using better_ll_ind; intros m h H.
  - simpl in H. destruct H as [contra | Hin]; try contradiction.
    auto.
  - simpl in H. destruct H as [[Hah | Hin] | Hin].
    + subst. simpl. auto.
    + simpl. auto.
    + right. apply IHl. auto.
Qed.
*)
Fixpoint LazyList_to_list {A : Type} (l : LazyList A) : list A :=
  match l with
  | lnil => nil
  | lcons x x0 => x :: LazyList_to_list (x0 tt)
  end.

Fixpoint list_to_LazyList {A : Type} (l : list A) : LazyList A :=
  match l with
  | nil => lnil _
  | cons x x0 => lcons _ x (fun _ => (list_to_LazyList x0))
  end.

(*
Theorem nil_lazylist :
  forall A (l : LazyList A),
    [] = LazyList_to_list l -> l = lnil A.
Proof.
  intros A l H.
  destruct l.
  - reflexivity.
  - inversion H.
Qed.

Theorem lazy_in_map:
  forall (A B : Type) (f : A -> B) (l : LazyList A) (x : A), In_ll x l -> In_ll (f x) (fmap f l).
Proof.
  intros A B f l.
  induction l using better_ll_ind; intros x H.
  - inversion H.
  - simpl in *. destruct H as [Hax | Hin].
    + left. subst; reflexivity.
    + right. auto.
Qed.

Lemma lazy_append_nil_r :
  forall {B : Type} (b : B) l,
    In_ll b l ->
    In_ll b (lazy_append l (lnil _)).
Proof.
  intros B b l H.
  induction l using better_ll_ind.
  - inversion H.
  - simpl in *. firstorder.
Qed.

Lemma lazy_append_in_l :
  forall {B : Type} (b : B) l ll,
    In_ll b l ->
    In_ll b (lazy_append l ll).
Proof.
  intros B b l ll H.
  induction ll using better_ll_ind.
  - auto using lazy_append_nil_r.
  - induction l using better_ll_ind.
    + inversion H.
    + simpl in *. firstorder.
Qed.

Lemma lazy_append_in_r :
  forall {B : Type} (b : B) l ll,
    In_ll b ll ->
    In_ll b (lazy_append l ll).
Proof.
  intros B b l ll H.
  induction l using better_ll_ind; simpl; auto.
Qed.

Lemma lazy_concat_in :
  forall {B : Type} (b : B) l ll,
    In_ll b l ->
    In_ll l ll ->
    In_ll b (concatLazyList ll).
Proof.
  intros B b l ll Hb Hbll.
  induction ll using better_ll_ind.
  - inversion Hbll.
  - simpl in *. destruct Hbll as [Hal | Hinl]; subst;
                  auto using lazy_append_in_l, lazy_append_in_r.
Qed.
 *)

Fixpoint join_list_lazy_list {A : Type} (l : list (LazyList A)) : LazyList A :=
  match l with
  | nil => lnil _
  | cons h ts => lazy_append h (join_list_lazy_list ts)
  end.

Fixpoint joint_list_lazy_list_list {A : Type} (l : list (LazyList A)) : list A :=
  match l with
  | nil => nil
  | cons h ts => (LazyList_to_list h) ++ (joint_list_lazy_list_list ts)
  end.