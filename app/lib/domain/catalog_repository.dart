import 'catalog_models.dart';

abstract interface class CatalogRepository {
  Future<List<CatalogType>> getTypes();

  Future<List<EggGroupSummary>> getEggGroups();

  Future<List<PetSummary>> searchHandbooks(PetQuery query);

  Future<List<PetSummary>> searchPets(PetQuery query);

  Future<PetDetail> getPetDetail(String petId);

  Future<List<PetSummary>> getFormsForHandbook(String handbookId);

  Future<PetSkillBundle> getSkillsForPet(String petId);

  Future<List<SkillSummary>> searchSkills(SkillQuery query);

  Future<List<SkillSummary>> getSkillsForDescriptionNote(String noteId);

  Future<SkillDetail> getSkillDetail(String skillId);

  Future<List<SkillUser>> getSkillUsers(
    String skillId, {
    required bool feature,
  });

  Future<EvolutionGraph> getEvolutionGraph(String petId);

  Future<CatalogInfo> getCatalogInfo();
}
