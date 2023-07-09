"""Extensions for bzlmod.

Installs a acados toolchain.
Every module can define a toolchain version under the default name, "acados".
The latest of those versions will be selected (the rest discarded),
and will always be registered by rules_acados.

Additionally, the root module can define arbitrarily many more toolchain versions under different
names (the latest version will be picked for each name) and can register them as it sees fit,
effectively overriding the default named toolchain due to toolchain resolution precedence.
"""

load(":repositories.bzl", "acados_register_toolchains")

_DEFAULT_NAME = "acados"

acados_toolchain = tag_class(attrs = {
    "name": attr.string(doc = """\
Base name for generated repositories, allowing more than one acados toolchain to be registered.
Overriding the default is only permitted in the root module.
""", default = _DEFAULT_NAME),
    "acados_version": attr.string(doc = "Explicit version of acados.", mandatory = True),
})

def _toolchain_extension(module_ctx):
    registrations = {}
    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            if toolchain.name != _DEFAULT_NAME and not mod.is_root:
                fail("""\
                Only the root module may override the default name for the acados toolchain.
                This prevents conflicting registrations in the global namespace of external repos.
                """)
            if toolchain.name not in registrations.keys():
                registrations[toolchain.name] = []
            registrations[toolchain.name].append(toolchain.acados_version)
    for name, versions in registrations.items():
        if len(versions) > 1:
            # TODO: should be semver-aware, using MVS
            selected = sorted(versions, reverse = True)[0]

            # buildifier: disable=print
            print("NOTE: acados toolchain {} has multiple versions {}, selected {}".format(name, versions, selected))
        else:
            selected = versions[0]

        acados_register_toolchains(
            name = name,
            acados_version = selected,
            register = False,
        )

acados = module_extension(
    implementation = _toolchain_extension,
    tag_classes = {"toolchain": acados_toolchain},
)
