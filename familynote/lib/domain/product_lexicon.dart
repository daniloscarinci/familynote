/// Supermarket aisles in the fixed order they are shown to people.
enum ShoppingCategory {
  hortifruti('Hortifruti'),
  padaria('Padaria'),
  acougue('Açougue e peixes'),
  frios('Frios e laticínios'),
  mercearia('Mercearia'),
  bebidas('Bebidas'),
  congelados('Congelados'),
  limpeza('Limpeza'),
  higiene('Higiene e perfumaria'),
  bebePet('Bebê e pet'),
  outros('Outros');

  const ShoppingCategory(this.label);
  final String label;
}

/// Built-in pt-BR product words (singular, written with accents; they are
/// normalized when the lexicon is loaded). Plurals are resolved by the
/// organizer. Multi-word entries are matched as phrases.
const Map<ShoppingCategory, String> productWords = {
  ShoppingCategory.hortifruti:
      'alface tomate cebola alho batata cenoura banana maçã laranja limão abacaxi melancia melão '
      'mamão uva morango manga abacate pera pêssego ameixa kiwi goiaba maracujá coco beterraba '
      'pepino pimentão abobrinha abóbora berinjela brócolis couve couve-flor repolho espinafre '
      'rúcula agrião salsinha cebolinha coentro manjericão hortelã gengibre chuchu quiabo '
      'mandioca aipim macaxeira inhame milho vagem ervilha cogumelo champignon tangerina '
      'mexerica bergamota cheiro-verde fruta verdura legume batata-doce acelga alho-poró '
      'rabanete limão-siciliano mamão-papaia caqui figo nectarina cereja lima pitaya jabuticaba '
      'folha louro alecrim tomilho',
  ShoppingCategory.padaria:
      'pão pãozinho pão-de-forma pão-francês pão-de-queijo bisnaga baguete croissant rosca sonho '
      'torrada broa bolo cuca pão-integral pão-de-hambúrguer pão-de-hot-dog panetone '
      'pão-sírio pão-de-leite carolina',
  ShoppingCategory.acougue:
      'carne carne-moída bife frango peito-de-frango coxa sobrecoxa linguiça salsicha bacon '
      'picanha alcatra patinho acém costela fraldinha contrafilé maminha filé peixe tilápia '
      'salmão sardinha camarão bacalhau merluza pescada hambúrguer peru porco lombo pernil '
      'fígado moela coxão-mole cupim lagarto músculo filé-mignon file-de-peixe tainha '
      'peixe-fresco carne-seca',
  ShoppingCategory.frios:
      'leite queijo mussarela muçarela presunto requeijão manteiga margarina iogurte '
      'creme-de-leite leite-condensado nata ricota parmesão cream-cheese mortadela salame '
      'peito-de-peru coalhada queijo-ralado leite-em-pó chantilly kefir queijo-minas prato '
      'provolone gorgonzola cheddar leite-integral leite-desnatado petit-suisse danoninho '
      'chocolate-quente-pronto salaminho copa lanche-de-peru',
  ShoppingCategory.mercearia:
      'arroz feijão macarrão espaguete massa açúcar sal café óleo azeite vinagre farinha fubá '
      'aveia biscoito bolacha molho extrato ketchup maionese mostarda atum ovo cereal granola '
      'chocolate achocolatado geleia mel amendoim castanha lentilha grão-de-bico tempero '
      'pimenta orégano canela fermento gelatina farofa tapioca polvilho cuscuz sopa salgadinho '
      'bala chiclete azeitona palmito leite-de-coco maisena chá adoçante pipoca batata-palha '
      'wafer barra-de-cereal pasta-de-amendoim conserva molho-de-tomate sardinha-em-lata '
      'milho-verde ervilha-em-lata cravo colorau páprica cominho louro-em-folha caldo '
      'açúcar-mascavo sal-grosso farinha-de-trigo farinha-de-mandioca macarrão-instantâneo '
      'miojo lasanha-seca bombom paçoca doce-de-leite goiabada compota nozes uva-passa '
      'amido corante essência',
  ShoppingCategory.bebidas:
      'água suco refrigerante cerveja vinho guaraná coca-cola água-de-coco energético '
      'isotônico whisky vodka cachaça espumante champanhe chá-gelado água-com-gás '
      'água-mineral tônica licor gin guaraná-antarctica fanta sprite néctar '
      'suco-de-laranja suco-de-uva água-de-garrafão garrafão',
  ShoppingCategory.congelados:
      'sorvete pizza lasanha nuggets polpa gelo picolé batata-frita empanado açaí '
      'legumes-congelados massa-folhada sobremesa congelado pizza-congelada espetinho '
      'pão-de-queijo-congelado hambúrguer-congelado frango-congelado',
  ShoppingCategory.limpeza:
      'detergente sabão sabão-em-pó amaciante água-sanitária desinfetante esponja vassoura rodo '
      'pano saco-de-lixo lixo multiuso álcool limpa-vidro cloro inseticida lustra-móveis '
      'papel-toalha guardanapo bucha luva balde alvejante sabão-em-barra flanela naftalina '
      'desengordurante lava-louça limpador pá-de-lixo vela fósforo isqueiro pilha lâmpada '
      'papel-alumínio papel-filme saco-plástico veja pinho-sol',
  ShoppingCategory.higiene:
      'papel-higiênico sabonete shampoo xampu condicionador creme-dental pasta-de-dente '
      'escova-de-dente fio-dental desodorante absorvente cotonete algodão barbeador lâmina '
      'perfume hidratante protetor-solar creme esmalte acetona lenço enxaguante antisséptico '
      'tintura talco preservativo pente escova gilete espuma-de-barbear sabonete-líquido '
      'creme-de-cabelo pomada band-aid curativo',
  ShoppingCategory.bebePet:
      'fralda lenço-umedecido mamadeira chupeta papinha ração areia-de-gato petisco coleira '
      'shampoo-pet sachê leite-infantil pomada-para-assadura biscoito-de-cachorro osso '
      'ração-de-gato ração-de-cachorro areia-higiênica brinquedo-de-cachorro',
};
