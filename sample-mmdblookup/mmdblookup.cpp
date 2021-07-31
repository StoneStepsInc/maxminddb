//
// Parts of this code are copied from the source file listed below
// and are subject to MaxMind's copyright and terms of use.
// 
// https://github.com/maxmind/libmaxminddb/blob/1.6.0/bin/mmdblookup.c
//
#include <maxminddb.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <malloc.h>

#include <stdexcept>
#include <string>

using namespace std::string_literals;

static void dump_meta(const MMDB_s *mmdb);
static void lookup_and_print(const MMDB_s *mmdb, const char *ip_address);

int main(int argc, char **argv)
{
   try {
      const char *mmdb_fname = "MaxMind-DB-test-ipv4-32.mmdb";
      const char *ip_address = "1.1.1.32";

      MMDB_s mmdb = {};

      int status = MMDB_open(mmdb_fname, MMDB_MODE_MMAP, &mmdb);

      if(status != MMDB_SUCCESS)
         throw std::runtime_error("Cannot open "s + mmdb_fname + "; "s + MMDB_strerror(status));

      dump_meta(&mmdb);

      lookup_and_print(&mmdb, ip_address);

      MMDB_close(&mmdb);

      return EXIT_SUCCESS;
   }
   catch (const std::exception& err) {
      fprintf(stderr, "%s\n", err.what());
   }
}

static void dump_meta(const MMDB_s *mmdb)
{
    const char *meta_dump = "\n"
                            "  Database metadata\n"
                            "    Node count:    %i\n"
                            "    Record size:   %i bits\n"
                            "    IP version:    IPv%i\n"
                            "    Binary format: %i.%i\n"
                            "    Build epoch:   %llu (%s)\n"
                            "    Type:          %s\n"
                            "    Languages:     ";

    char date[40];
    const time_t epoch = (const time_t)mmdb->metadata.build_epoch;
    strftime(date, 40, "%F %T UTC", gmtime(&epoch));

    fprintf(stdout,
            meta_dump,
            mmdb->metadata.node_count,
            mmdb->metadata.record_size,
            mmdb->metadata.ip_version,
            mmdb->metadata.binary_format_major_version,
            mmdb->metadata.binary_format_minor_version,
            mmdb->metadata.build_epoch,
            date,
            mmdb->metadata.database_type);

    for (size_t i = 0; i < mmdb->metadata.languages.count; i++) {
        fprintf(stdout, "%s", mmdb->metadata.languages.names[i]);
        if (i < mmdb->metadata.languages.count - 1) {
            fprintf(stdout, " ");
        }
    }
    fprintf(stdout, "\n");

    fprintf(stdout, "    Description:\n");
    for (size_t i = 0; i < mmdb->metadata.description.count; i++) {
        fprintf(stdout,
                "      %s:   %s\n",
                mmdb->metadata.description.descriptions[i]->language,
                mmdb->metadata.description.descriptions[i]->description);
    }
    fprintf(stdout, "\n");
}

static void lookup_and_print(const MMDB_s *mmdb, const char *ip_address)
{
   int gai_error, mmdb_error;

   MMDB_lookup_result_s result = MMDB_lookup_string(mmdb, ip_address, &gai_error, &mmdb_error);

   if (gai_error)
      throw std::runtime_error("getaddrinfo error: "s + ip_address + "; "s + gai_strerrorA(gai_error));

   if (mmdb_error != MMDB_SUCCESS)
      throw std::runtime_error("MMDB error (look-up): "s + MMDB_strerror(mmdb_error));

   if(!result.found_entry)
      throw std::runtime_error("Cannot find "s + ip_address);

   MMDB_entry_data_list_s *entry_data_list = nullptr;

   int status = MMDB_get_entry_data_list(&result.entry, &entry_data_list);

   if(status != MMDB_SUCCESS)
      throw std::runtime_error("MMDB error (entry data list): "s + MMDB_strerror(status));

   if(entry_data_list) {
      fprintf(stdout, "\n");
      MMDB_dump_entry_data_list(stdout, entry_data_list, 2);
      fprintf(stdout, "\n");

      MMDB_free_entry_data_list(entry_data_list);
   }
}


